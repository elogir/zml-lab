import 'package:freezed_annotation/freezed_annotation.dart';

import 'benchmark.dart';

part 'saved_benchmark.freezed.dart';

/// A named snapshot of a completed benchmark run, stored so it can be revisited
/// from the Saved benchmarks tab.
@freezed
abstract class SavedBenchmark with _$SavedBenchmark {
  const SavedBenchmark._();

  const factory SavedBenchmark({
    required String id,
    required String name,

    /// Where it ran, for display — e.g. `orion:8001`.
    required String endpoint,

    /// The machine it ran on (its friendly name). Null for runs saved before
    /// this was tracked — callers fall back to the endpoint's host.
    String? machineName,
    required String prompt,
    required int batchSize,
    required double aggregateTokensPerSecond,
    required int completed,
    required int medianTtftMs,
    required int elapsedMs,
    required DateTime createdAt,

    /// The per-request responses (text + metrics) captured at save time.
    @Default(<BenchmarkRequest>[]) List<BenchmarkRequest> requests,

    /// Throughput samples over the run, for the charts.
    @Default(<BenchmarkSample>[]) List<BenchmarkSample> samples,
  }) = _SavedBenchmark;

  /// The machine it ran on. Uses the stored [machineName], falling back to the
  /// host part of [endpoint] for runs saved before the machine was tracked.
  String get machineLabel =>
      machineName ??
      (endpoint.contains(':')
          ? endpoint.substring(0, endpoint.lastIndexOf(':'))
          : endpoint);

  /// The port part of [endpoint] (`:8001`), or the whole endpoint if it has no
  /// colon — shown next to [machineLabel] so the machine isn't repeated.
  String get portLabel => endpoint.contains(':')
      ? endpoint.substring(endpoint.lastIndexOf(':'))
      : endpoint;
}
