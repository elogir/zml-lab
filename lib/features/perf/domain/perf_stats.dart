/// Statistics over the benchmarker's event stream.
///
/// Definitions are the run format's (docs/perf-run-format.md; checked
/// against its SQL on the same run in test/perf_contract_test.dart), so the
/// app and anything reading a run file agree. A token is a streamed chunk
/// carrying text, answer or reasoning ([PerfEvent.hasText]):
///  - TTFT        = first token's timestamp - request_timestamp, per request
///                  (every turn of a conversation)
///  - ITL         = gaps between consecutive tokens of a request
///  - Req latency = max(timestamp) - request_timestamp, per request
///  - OSL / ISL   = max outputs/inputs_tokens per request (ISL skips zeros)
///  - Throughput  = tokens / (max timestamp - min request_timestamp)
///
/// The benchmarker's own `duckdb/report.sql` takes TTFT from seq 0 (which
/// can be an empty chunk, and only a conversation's first turn has one) and
/// ITL and throughput over every chunk, empty ones included.
library;

import 'dart:math' as math;

import '../../../models/perf_report.dart';
import 'csv_events.dart';

/// duckdb's `quantile_cont`: linear interpolation between closest ranks.
/// [sorted] must be ascending and non-empty.
double quantileCont(List<double> sorted, double q) {
  final h = (sorted.length - 1) * q;
  final lo = h.floor();
  final hi = h.ceil();
  if (lo == hi) return sorted[lo];
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (h - lo);
}

PerfStatRow _statRow(String label, String unit, List<double> values) {
  values.sort();
  final sum = values.fold(0.0, (a, b) => a + b);
  return PerfStatRow(
    label: label,
    unit: unit,
    avg: sum / values.length,
    min: values.first,
    max: values.last,
    p50: quantileCont(values, 0.50),
    p75: quantileCont(values, 0.75),
    p90: quantileCont(values, 0.90),
    p95: quantileCont(values, 0.95),
    p99: quantileCont(values, 0.99),
    p999: quantileCont(values, 0.999),
  );
}

class _RequestState {
  _RequestState(this.requestTimestampNs);

  final int requestTimestampNs;
  int maxTimestampNs = 0;
  int maxInputTokens = 0;
  int maxOutputTokens = 0;
  double? ttftMs;

  /// When its first token arrived (null: none yet).
  int? firstTokenTs;

  /// Timestamp of the request's previous token, for the ITL gaps.
  int? lastTokenTs;

  /// Its stream ended: the final usage chunk (the only one with prompt
  /// tokens) or an error came. Until then it's in flight, even through a
  /// stall with no chunks.
  bool done = false;
}

/// Ingests [PerfEvent]s as they stream in and produces both the live series
/// (for the charts while running) and the final [PerfReport] numbers.
class PerfAccumulator {
  /// Width of one live-series bucket — a chart point every 100 ms, so the
  /// live charts move smoothly.
  static const bucketMs = 100;

  /// Each point's rate is taken over this many trailing buckets (1 s), so the
  /// fine buckets don't make the line jitter.
  static const windowBuckets = 10;

  final Map<String, _RequestState> _requests = {};
  final List<double> _itlGapsMs = [];

  int _events = 0;
  int _tokens = 0;
  int _errors = 0;
  int _maxSeq = 0;
  int? _minRequestTsNs;
  int _maxTsNs = 0;

  /// Some request's end was seen (see [_RequestState.done]). A server that
  /// never reports usage gives none: then requests end at their last chunk.
  bool _sawEnd = false;

  // Live series: per-bucket token counts and requests first seen.
  final List<int> _bucketTokens = [];
  final List<int> _bucketNewRequests = [];

  /// Rates that can't change anymore (a window behind the newest bucket),
  /// so a long run's series isn't recomputed from scratch on every refresh.
  /// (The in-flight counts are, each time: a request can start counting
  /// seconds before its first event shows up.)
  final List<PerfSeriesPoint> _settled = [];

  String? _firstError;

  int get eventCount => _events;

  /// Chunks with text, answer or reasoning.
  int get tokenCount => _tokens;
  int get errorCount => _errors;
  int get requestCount => _requests.length;
  int get maxSeq => _maxSeq;

  /// The first error message the benchmarker reported (its CSV `error`
  /// column), for showing a representative reason alongside the error count.
  String? get firstError => _firstError;

  /// Tokens/second over the run so far.
  double get liveTokensPerSecond {
    final s = _totalSeconds;
    return s > 0 ? _tokens / s : 0;
  }

  double get _totalSeconds {
    final start = _minRequestTsNs;
    if (start == null || _maxTsNs <= start) return 0;
    return (_maxTsNs - start) / 1e9;
  }

  void addAll(List<PerfEvent> events) {
    for (final e in events) {
      _add(e);
    }
  }

  void _add(PerfEvent e) {
    _events++;
    if (e.isError) {
      _errors++;
      _firstError ??= e.error;
    }
    if (e.seq > _maxSeq) _maxSeq = e.seq;
    _minRequestTsNs = math.min(
      _minRequestTsNs ?? e.requestTimestampNs,
      e.requestTimestampNs,
    );
    _maxTsNs = math.max(_maxTsNs, e.timestampNs);

    final isNew = !_requests.containsKey(e.requestId);
    final r = _requests.putIfAbsent(
      e.requestId,
      () => _RequestState(e.requestTimestampNs),
    );
    r.maxTimestampNs = math.max(r.maxTimestampNs, e.timestampNs);
    r.maxInputTokens = math.max(r.maxInputTokens, e.inputTokens);
    r.maxOutputTokens = math.max(r.maxOutputTokens, e.outputTokens);
    if (e.hasText) {
      _tokens++;
      // A request's chunks arrive in order: its first token is the first
      // one seen.
      r.ttftMs ??= (e.timestampNs - e.requestTimestampNs) / 1e6;
      r.firstTokenTs ??= e.timestampNs;
      final last = r.lastTokenTs;
      if (last != null) _itlGapsMs.add((e.timestampNs - last) / 1e6);
      r.lastTokenTs = e.timestampNs;
    }
    if (e.ends) r.done = _sawEnd = true;

    // Live series bucket, indexed from the run's first request timestamp.
    final start = _minRequestTsNs!;
    final bucket = math.max(0, (e.timestampNs - start) ~/ (bucketMs * 1000000));
    while (_bucketTokens.length <= bucket) {
      _bucketTokens.add(0);
      _bucketNewRequests.add(0);
    }
    if (e.hasText) _bucketTokens[bucket]++;
    if (isNew) _bucketNewRequests[bucket]++;
  }

  /// The time series so far: a point per bucket (at its end), its rate over
  /// the trailing [windowBuckets], and the requests in flight at that
  /// instant. While running the last (partial) bucket is dropped so the tail
  /// of the chart doesn't dip.
  List<PerfSeriesPoint> series({required bool includeLast}) {
    final n = includeLast ? _bucketTokens.length : _bucketTokens.length - 1;
    if (n <= 0) return const [];
    // Late events (out-of-order rows) can still land in the newest window.
    final settled = math.min(n, _bucketTokens.length - 1 - windowBuckets);
    while (_settled.length < settled) {
      _settled.add(_point(_settled.length, _settled.lastOrNull?.requests ?? 0));
    }
    final rates = _settled.length <= n
        ? List.of(_settled)
        : _settled.sublist(0, n);
    while (rates.length < n) {
      rates.add(_point(rates.length, rates.lastOrNull?.requests ?? 0));
    }
    final (inFlight, waiting) = _inFlight(n);
    return [
      for (final (i, p) in rates.indexed)
        PerfSeriesPoint(
          elapsedMs: p.elapsedMs,
          tps: p.tps,
          active: inFlight[i],
          waiting: waiting[i],
          requests: p.requests,
        ),
    ];
  }

  PerfSeriesPoint _point(int i, int requestsBefore) {
    final from = math.max(0, i - windowBuckets + 1);
    var tokens = 0;
    for (var j = from; j <= i; j++) {
      tokens += _bucketTokens[j];
    }
    final seconds = (i - from + 1) * bucketMs / 1000;
    return PerfSeriesPoint(
      elapsedMs: (i + 1) * bucketMs,
      tps: tokens / seconds,
      active: 0,
      requests: requestsBefore + _bucketNewRequests[i],
    );
  }

  /// At the end of each of the first [n] buckets: the requests in flight
  /// (sent, stream not ended) and, of those, the ones still waiting for a
  /// first token. One pass over the requests (difference arrays), so it's
  /// cheap to redo on every refresh.
  (List<int>, List<int>) _inFlight(int n) {
    final start = _minRequestTsNs!;
    const width = bucketMs * 1000000;
    // The first point at or after [ns] (point i is at start + (i+1)·width).
    int at(int ns) =>
        math.min(n, math.max(0, ((ns - start) / width).ceil() - 1));
    final inFlight = List.filled(n + 1, 0);
    final waiting = List.filled(n + 1, 0);
    for (final r in _requests.values) {
      final from = at(r.requestTimestampNs);
      // Unfinished: in flight to the newest point.
      final until = r.done || !_sawEnd ? at(r.maxTimestampNs) : n;
      if (from < until) {
        inFlight[from]++;
        inFlight[until]--;
      }
      final first = r.firstTokenTs;
      final waitUntil = first == null ? until : math.min(until, at(first));
      if (from < waitUntil) {
        waiting[from]++;
        waiting[waitUntil]--;
      }
    }
    for (var i = 1; i < n; i++) {
      inFlight[i] += inFlight[i - 1];
      waiting[i] += waiting[i - 1];
    }
    return (inFlight, waiting);
  }

  List<PerfStatRow> statRows() {
    final ttft = [
      for (final r in _requests.values)
        if (r.ttftMs != null) r.ttftMs!,
    ];
    final latency = [
      for (final r in _requests.values)
        (r.maxTimestampNs - r.requestTimestampNs) / 1e6,
    ];
    final osl = [
      for (final r in _requests.values) r.maxOutputTokens.toDouble(),
    ];
    final isl = [
      for (final r in _requests.values)
        if (r.maxInputTokens != 0) r.maxInputTokens.toDouble(),
    ];
    return [
      if (ttft.isNotEmpty) _statRow('Time to first token', 'ms', ttft),
      if (_itlGapsMs.isNotEmpty)
        _statRow('Inter-token latency', 'ms', List.of(_itlGapsMs)),
      if (latency.isNotEmpty) _statRow('Request latency', 'ms', latency),
      if (osl.isNotEmpty) _statRow('Output sequence length', 'tok', osl),
      if (isl.isNotEmpty) _statRow('Input sequence length', 'tok', isl),
    ];
  }

  /// A latency distribution in [bins] uniform buckets. The range is capped
  /// at ~p99 so a few stragglers don't flatten the whole histogram; values
  /// beyond the cap land in the last bucket.
  static PerfHistogram _histogram(List<double> values, int bins) {
    if (values.isEmpty) {
      return const PerfHistogram(binWidthMs: 1, binStartMs: 0, counts: []);
    }
    final sorted = List.of(values)..sort();
    final lo = sorted.first;
    final hi = math.max(quantileCont(sorted, 0.99) * 1.25, lo + 1e-9);
    final width = (hi - lo) / bins;
    final counts = List.filled(bins, 0);
    for (final v in sorted) {
      counts[math.min(((v - lo) / width).floor(), bins - 1)]++;
    }
    return PerfHistogram(binWidthMs: width, binStartMs: lo, counts: counts);
  }

  /// Time-to-first-token distribution across requests.
  PerfHistogram ttftHistogram({int bins = 30}) => _histogram([
    for (final r in _requests.values)
      if (r.ttftMs != null) r.ttftMs!,
  ], bins);

  /// Inter-token latency distribution across all gaps.
  PerfHistogram itlHistogram({int bins = 40}) => _histogram(_itlGapsMs, bins);

  double get totalSeconds => _totalSeconds;
  double get tokensPerSecond => liveTokensPerSecond;
  double get requestsPerSecond {
    final s = _totalSeconds;
    return s > 0 ? _requests.length / s : 0;
  }
}
