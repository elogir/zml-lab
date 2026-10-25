import 'package:freezed_annotation/freezed_annotation.dart';

import 'benchmark.dart';
import 'run_meta.dart';

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

    /// The model name sent with the requests. Null for runs saved before this
    /// was tracked.
    String? model,

    /// Edited afterwards, as a perf run's meta.json (see [details]): a name
    /// shown instead of [model] (which stays what was sent), the hardware,
    /// the server's version and commit, tags and notes. Null/empty = none.
    String? modelAlias,
    String? hardware,
    String? serverVersion,
    String? serverCommit,
    @Default(<String>[]) List<String> tags,
    @Default('') String notes,

    /// Per-request output cap; null = unlimited (or not tracked).
    int? maxTokens,

    /// Sampling temperature; null = the server's default (or not tracked).
    double? temperature,

    /// Whether the run ignored EOS (replies ran to the token cap).
    @Default(false) bool ignoreEos,
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

  /// The model as lists show it: [modelAlias], else what was sent.
  String? get displayModel => modelAlias ?? model;

  /// The details a person edits ([runMetaFields]).
  RunDetails get details => RunDetails(
    label: name,
    model: displayModel ?? '',
    hardware: hardware ?? '',
    serverVersion: serverVersion ?? '',
    serverCommit: serverCommit ?? '',
    tags: tags,
    notes: notes,
  );

  /// This run with [d] as its details; a model equal to the one sent (or
  /// none) drops the alias.
  SavedBenchmark withDetails(RunDetails d) => copyWith(
    name: d.label,
    modelAlias: d.model.isEmpty || d.model == model ? null : d.model,
    hardware: d.hardware.isEmpty ? null : d.hardware,
    serverVersion: d.serverVersion.isEmpty ? null : d.serverVersion,
    serverCommit: d.serverCommit.isEmpty ? null : d.serverCommit,
    tags: d.tags,
    notes: d.notes,
  );

  /// Mean per-request tok/s across the saved run (see [meanRequestTps]).
  double get averageTokensPerSecond => meanRequestTps(requests);
}
