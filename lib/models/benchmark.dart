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
  const factory BenchmarkRequest({
    required int index,
    @Default(BenchmarkRequestStatus.queued) BenchmarkRequestStatus status,
    @Default('') String text,
    @Default(0) int tokens,
    @Default(0) double tokensPerSecond,
    int? ttftMs,
    int? latencyMs,
  }) = _BenchmarkRequest;
}

/// Aggregate state of a benchmark run over a batch of requests.
@freezed
abstract class BenchmarkRun with _$BenchmarkRun {
  const BenchmarkRun._();

  const factory BenchmarkRun({
    required String prompt,
    required int batchSize,
    @Default(<BenchmarkRequest>[]) List<BenchmarkRequest> requests,
    @Default(false) bool isRunning,
    @Default(Duration.zero) Duration elapsed,
  }) = _BenchmarkRun;

  int get completed =>
      requests.where((r) => r.status.isTerminal).length;

  /// Combined throughput of every request currently producing tokens.
  double get aggregateTokensPerSecond => requests
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
