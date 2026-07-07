/// Statistics over the benchmarker's event stream.
///
/// Definitions mirror the tool's own `duckdb/report.sql` exactly (verified
/// against duckdb on the same CSV in test/perf_stats_test.dart), so numbers
/// shown here match what the team quotes from the CLI pipeline:
///  - TTFT        = (timestamp - request_timestamp) of events with seq == 0
///  - ITL         = gaps between consecutive seq > 0 events within a request
///                  (the seq0→seq1 gap is excluded, as in the SQL's LAG over
///                  the seq > 0 subset)
///  - Req latency = max(timestamp) - request_timestamp, per request
///  - OSL / ISL   = max outputs/inputs_tokens per request (ISL skips zeros)
///  - Throughput  = total events / (max timestamp - min request_timestamp)
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

  /// Timestamp of the previous seq > 0 event, for the ITL gaps.
  int? lastPositiveSeqTs;
}

/// Ingests [PerfEvent]s as they stream in and produces both the live series
/// (for the charts while running) and the final [PerfReport] numbers.
class PerfAccumulator {
  /// Width of one live-series bucket.
  static const bucketMs = 500;

  final Map<String, _RequestState> _requests = {};
  final List<double> _itlGapsMs = [];

  int _events = 0;
  int _errors = 0;
  int _maxSeq = 0;
  int? _minRequestTsNs;
  int _maxTsNs = 0;
  String server = '';

  // Live series: per-bucket event counts and distinct streaming requests.
  final List<int> _bucketEvents = [];
  final List<Set<String>> _bucketIds = [];

  /// First-seen bucket per request, for the cumulative request count.
  final Map<String, int> _firstBucket = {};

  int get eventCount => _events;
  int get errorCount => _errors;
  int get requestCount => _requests.length;
  int get maxSeq => _maxSeq;

  /// Events/second over the run so far (the tool's tokens_per_second).
  double get liveTokensPerSecond {
    final s = _totalSeconds;
    return s > 0 ? _events / s : 0;
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
    if (e.isError) _errors++;
    if (e.seq > _maxSeq) _maxSeq = e.seq;
    if (e.server.isNotEmpty) server = e.server;
    _minRequestTsNs = math.min(
      _minRequestTsNs ?? e.requestTimestampNs,
      e.requestTimestampNs,
    );
    _maxTsNs = math.max(_maxTsNs, e.timestampNs);

    final r = _requests.putIfAbsent(
      e.requestId,
      () => _RequestState(e.requestTimestampNs),
    );
    r.maxTimestampNs = math.max(r.maxTimestampNs, e.timestampNs);
    r.maxInputTokens = math.max(r.maxInputTokens, e.inputTokens);
    r.maxOutputTokens = math.max(r.maxOutputTokens, e.outputTokens);
    if (e.seq == 0) {
      r.ttftMs = (e.timestampNs - e.requestTimestampNs) / 1e6;
    } else {
      final last = r.lastPositiveSeqTs;
      if (last != null) _itlGapsMs.add((e.timestampNs - last) / 1e6);
      r.lastPositiveSeqTs = e.timestampNs;
    }

    // Live series bucket, indexed from the run's first request timestamp.
    final start = _minRequestTsNs!;
    final bucket = math.max(0, (e.timestampNs - start) ~/ (bucketMs * 1000000));
    while (_bucketEvents.length <= bucket) {
      _bucketEvents.add(0);
      _bucketIds.add(<String>{});
    }
    _bucketEvents[bucket]++;
    _bucketIds[bucket].add(e.requestId);
    _firstBucket.putIfAbsent(e.requestId, () => bucket);
  }

  /// The time series so far. While running the last (partial) bucket is
  /// dropped so the tail of the chart doesn't dip.
  List<PerfSeriesPoint> series({required bool includeLast}) {
    final n = includeLast ? _bucketEvents.length : _bucketEvents.length - 1;
    if (n <= 0) return const [];
    final counts = List.filled(n, 0);
    for (final entry in _firstBucket.entries) {
      if (entry.value < n) counts[entry.value]++;
    }
    var cumulative = 0;
    return [
      for (var i = 0; i < n; i++)
        PerfSeriesPoint(
          elapsedMs: (i + 1) * bucketMs,
          tps: _bucketEvents[i] * 1000 / bucketMs,
          active: _bucketIds[i].length,
          requests: cumulative += counts[i],
        ),
    ];
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
  PerfHistogram ttftHistogram({int bins = 30}) => _histogram(
    [
      for (final r in _requests.values)
        if (r.ttftMs != null) r.ttftMs!,
    ],
    bins,
  );

  /// Inter-token latency distribution across all gaps.
  PerfHistogram itlHistogram({int bins = 40}) =>
      _histogram(_itlGapsMs, bins);

  double get totalSeconds => _totalSeconds;
  double get tokensPerSecond => liveTokensPerSecond;
  double get requestsPerSecond {
    final s = _totalSeconds;
    return s > 0 ? _requests.length / s : 0;
  }
}
