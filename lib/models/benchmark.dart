import 'package:freezed_annotation/freezed_annotation.dart';

part 'benchmark.freezed.dart';

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

    /// Bumped each time a new batch is started. Chats opened from a request
    /// key their seed to this, so they reset when the run they came from is
    /// replaced.
    @Default(0) int runToken,
    @Default(<BenchmarkRequest>[]) List<BenchmarkRequest> requests,
    @Default(false) bool isRunning,
    @Default(Duration.zero) Duration elapsed,
    // The aggregate throughput captured at full concurrency (see
    // [aggregateTokensPerSecond]). 0 until the first request finishes, then
    // held static for the rest of the run and after.
    @Default(0.0) double frozenAggregate,
  }) = _BenchmarkRun;

  int get completed =>
      requests.where((r) => r.status.isTerminal).length;

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
