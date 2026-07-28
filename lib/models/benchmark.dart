import 'package:freezed_annotation/freezed_annotation.dart';

part 'benchmark.freezed.dart';

/// One time-series point sampled during a run: at [elapsedMs] into the run the
/// batch was producing [tps] tokens/second in aggregate (summed over the
/// requests still streaming) at an [avgTps] average per those requests, having
/// generated [tokens] tokens total. Plotted to show throughput over time (its
/// slope) — the aggregate ramps up and decays with concurrency, while the
/// average shows single-request speed (which rises as contention drops).
class BenchmarkSample {
  const BenchmarkSample({
    required this.elapsedMs,
    required this.tps,
    required this.avgTps,
    required this.tokens,
  });

  final int elapsedMs;
  final double tps;
  final double avgTps;
  final int tokens;

  Map<String, dynamic> toMap() =>
      {'t': elapsedMs, 'r': tps, 'a': avgTps, 'n': tokens};

  factory BenchmarkSample.fromMap(Map<String, dynamic> m) => BenchmarkSample(
    elapsedMs: (m['t'] as num?)?.toInt() ?? 0,
    tps: (m['r'] as num?)?.toDouble() ?? 0,
    // Older saved runs predate the average; fall back to the aggregate so the
    // line isn't pinned at zero for them.
    avgTps: (m['a'] as num?)?.toDouble() ?? (m['r'] as num?)?.toDouble() ?? 0,
    tokens: (m['n'] as num?)?.toInt() ?? 0,
  );
}

/// The mean tok/s over the requests that produced any output — the per-request
/// average, shared by live [BenchmarkRun]s and saved runs.
double meanRequestTps(List<BenchmarkRequest> requests) {
  final rates = [
    for (final r in requests)
      if (r.tokensPerSecond > 0) r.tokensPerSecond,
  ];
  if (rates.isEmpty) return 0;
  return rates.reduce((a, b) => a + b) / rates.length;
}

/// State of a single in-flight benchmark request.
enum BenchmarkRequestStatus {
  queued,
  streaming,
  done,
  failed;

  String get label => switch (this) {
    BenchmarkRequestStatus.queued => 'queued',
    BenchmarkRequestStatus.streaming => 'streaming',
    BenchmarkRequestStatus.done => 'done',
    BenchmarkRequestStatus.failed => 'failed',
  };

  bool get isTerminal =>
      this == BenchmarkRequestStatus.done ||
      this == BenchmarkRequestStatus.failed;
}

/// One request in a benchmark batch, streaming its response.
@freezed
abstract class BenchmarkRequest with _$BenchmarkRequest {
  const BenchmarkRequest._();

  const factory BenchmarkRequest({
    required int index,
    @Default(BenchmarkRequestStatus.queued) BenchmarkRequestStatus status,
    @Default('') String text,

    /// The model's thinking output (from `reasoning_content`), shown above the
    /// answer for reasoning models. Empty when the model doesn't emit any.
    @Default('') String reasoning,
    @Default(0) int tokens,
    @Default(0) double tokensPerSecond,
    int? ttftMs,
    int? latencyMs,

    /// The server's `finish_reason` for the reply, once one arrived
    /// (`stop`, `length`, `tool_calls`, …).
    String? finishReason,

    /// Why the request failed, when [status] is `failed` — the HTTP error
    /// (status + body) or the connection error, shown on the card.
    String? error,
  }) = _BenchmarkRequest;

  /// Whether the reply was cut off by a token limit rather than finishing
  /// naturally — the server reports `length` both for a request-level
  /// max-tokens cap and for its own max sequence length.
  bool get truncated => finishReason == 'length';
}

/// Aggregate state of a benchmark run over a batch of requests.
@freezed
abstract class BenchmarkRun with _$BenchmarkRun {
  const BenchmarkRun._();

  const factory BenchmarkRun({
    required String prompt,
    required int batchSize,

    /// Per-request output-token cap. Null means unlimited — the server decides
    /// (it stops at its max sequence length).
    int? maxTokens,

    /// Sampling temperature. Null means the server's default.
    double? temperature,

    /// Model name sent with each request (vLLM requires the real one; llmd
    /// ignores it). Empty = send `zml_model`.
    @Default('') String model,

    /// Bumped each time a new batch is started. Chats opened from a request
    /// key their seed to this, so they reset when the run they came from is
    /// replaced.
    @Default(0) int runToken,
    @Default(<BenchmarkRequest>[]) List<BenchmarkRequest> requests,

    /// Throughput samples over the run, for the charts (see [BenchmarkSample]).
    @Default(<BenchmarkSample>[]) List<BenchmarkSample> samples,
    @Default(false) bool isRunning,
    @Default(Duration.zero) Duration elapsed,
    // The aggregate throughput captured at full concurrency (see
    // [aggregateTokensPerSecond]). 0 until the first request finishes, then
    // held static for the rest of the run and after.
    @Default(0.0) double frozenAggregate,
  }) = _BenchmarkRun;

  int get completed =>
      requests.where((r) => r.status.isTerminal).length;

  /// Mean decode rate of a single request across the run — the average of each
  /// request's tok/s (over those that produced any). Unlike [aggregateTokens
  /// PerSecond] this doesn't scale with batch size, so it reads as "how fast is
  /// one request" rather than "total throughput".
  double get averageTokensPerSecond => meanRequestTps(requests);

  /// Requests whose reply was cut off by a token limit (max seqlen or the
  /// configured cap).
  int get truncatedCount => requests.where((r) => r.truncated).length;

  /// Whether the aggregate reading has been locked in — true once at least one
  /// request in the batch has finished.
  bool get aggregateFrozen => frozenAggregate > 0;

  /// Combined throughput of the batch *at full concurrency*. While every
  /// request is still streaming this is the live sum of their rates; the moment
  /// the first request finishes it freezes at [frozenAggregate] and holds.
  ///
  /// It has to freeze there: once the batch drops below its starting size the
  /// server has fewer requests to serve, so the survivors each speed up. Their
  /// combined rate would then keep climbing and no longer describe throughput
  /// at the batch size that was actually launched.
  double get aggregateTokensPerSecond => aggregateFrozen
      ? frozenAggregate
      : requests
            .where((r) => r.status == BenchmarkRequestStatus.streaming)
            .fold(0.0, (sum, r) => sum + r.tokensPerSecond);

  /// Median time-to-first-token over requests that have reported one.
  int get medianTtftMs {
    final ttfts = requests
        .map((r) => r.ttftMs)
        .whereType<int>()
        .toList()
      ..sort();
    if (ttfts.isEmpty) return 0;
    final mid = ttfts.length ~/ 2;
    return ttfts.length.isOdd
        ? ttfts[mid]
        : ((ttfts[mid - 1] + ttfts[mid]) / 2).round();
  }
}
