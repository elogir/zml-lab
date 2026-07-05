// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'benchmark_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives a real benchmark run: fires [batchSize] concurrent streaming requests
/// at the job's `/v1/chat/completions` endpoint and reports per-request and
/// aggregate throughput live. Cancelable mid-flight.
///
/// Keep-alive (keyed by job id) so a run — and the prompt/batch settings —
/// survive switching to the terminal tab or navigating away and back. The live
/// requests keep streaming in the background; invalidating the provider (or
/// cancelling) aborts them.

@ProviderFor(BenchmarkController)
final benchmarkControllerProvider = BenchmarkControllerFamily._();

/// Drives a real benchmark run: fires [batchSize] concurrent streaming requests
/// at the job's `/v1/chat/completions` endpoint and reports per-request and
/// aggregate throughput live. Cancelable mid-flight.
///
/// Keep-alive (keyed by job id) so a run — and the prompt/batch settings —
/// survive switching to the terminal tab or navigating away and back. The live
/// requests keep streaming in the background; invalidating the provider (or
/// cancelling) aborts them.
final class BenchmarkControllerProvider
    extends $NotifierProvider<BenchmarkController, BenchmarkRun> {
  /// Drives a real benchmark run: fires [batchSize] concurrent streaming requests
  /// at the job's `/v1/chat/completions` endpoint and reports per-request and
  /// aggregate throughput live. Cancelable mid-flight.
  ///
  /// Keep-alive (keyed by job id) so a run — and the prompt/batch settings —
  /// survive switching to the terminal tab or navigating away and back. The live
  /// requests keep streaming in the background; invalidating the provider (or
  /// cancelling) aborts them.
  BenchmarkControllerProvider._({
    required BenchmarkControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'benchmarkControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$benchmarkControllerHash();

  @override
  String toString() {
    return r'benchmarkControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BenchmarkController create() => BenchmarkController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BenchmarkRun value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BenchmarkRun>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BenchmarkControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$benchmarkControllerHash() =>
    r'067cd1eebde2201361d81b2999e204530c68c50a';

/// Drives a real benchmark run: fires [batchSize] concurrent streaming requests
/// at the job's `/v1/chat/completions` endpoint and reports per-request and
/// aggregate throughput live. Cancelable mid-flight.
///
/// Keep-alive (keyed by job id) so a run — and the prompt/batch settings —
/// survive switching to the terminal tab or navigating away and back. The live
/// requests keep streaming in the background; invalidating the provider (or
/// cancelling) aborts them.

final class BenchmarkControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          BenchmarkController,
          BenchmarkRun,
          BenchmarkRun,
          BenchmarkRun,
          String
        > {
  BenchmarkControllerFamily._()
    : super(
        retry: null,
        name: r'benchmarkControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Drives a real benchmark run: fires [batchSize] concurrent streaming requests
  /// at the job's `/v1/chat/completions` endpoint and reports per-request and
  /// aggregate throughput live. Cancelable mid-flight.
  ///
  /// Keep-alive (keyed by job id) so a run — and the prompt/batch settings —
  /// survive switching to the terminal tab or navigating away and back. The live
  /// requests keep streaming in the background; invalidating the provider (or
  /// cancelling) aborts them.

  BenchmarkControllerProvider call(String jobId) =>
      BenchmarkControllerProvider._(argument: jobId, from: this);

  @override
  String toString() => r'benchmarkControllerProvider';
}

/// Drives a real benchmark run: fires [batchSize] concurrent streaming requests
/// at the job's `/v1/chat/completions` endpoint and reports per-request and
/// aggregate throughput live. Cancelable mid-flight.
///
/// Keep-alive (keyed by job id) so a run — and the prompt/batch settings —
/// survive switching to the terminal tab or navigating away and back. The live
/// requests keep streaming in the background; invalidating the provider (or
/// cancelling) aborts them.

abstract class _$BenchmarkController extends $Notifier<BenchmarkRun> {
  late final _$args = ref.$arg as String;
  String get jobId => _$args;

  BenchmarkRun build(String jobId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BenchmarkRun, BenchmarkRun>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BenchmarkRun, BenchmarkRun>,
              BenchmarkRun,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
