import 'package:freezed_annotation/freezed_annotation.dart';

import 'benchmark.dart';

part 'saved_benchmark.freezed.dart';

/// A named snapshot of a completed benchmark run, stored so it can be revisited
/// from the Saved benchmarks tab.
@freezed
abstract class SavedBenchmark with _$SavedBenchmark {
  const factory SavedBenchmark({
    required String id,
    required String name,

    /// Where it ran, for display — e.g. `orion:8001`.
    required String endpoint,
    required String prompt,
    required int batchSize,
    required double aggregateTokensPerSecond,
    required int completed,
    required int medianTtftMs,
    required int elapsedMs,
    required DateTime createdAt,

    /// The per-request responses (text + metrics) captured at save time.
    @Default(<BenchmarkRequest>[]) List<BenchmarkRequest> requests,
  }) = _SavedBenchmark;
}
