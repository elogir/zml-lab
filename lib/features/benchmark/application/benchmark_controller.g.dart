// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'benchmark_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives a fake benchmark run: a batch of requests that stream tokens with
/// live per-request and aggregate throughput. Cancelable mid-flight.

@ProviderFor(BenchmarkController)
final benchmarkControllerProvider = BenchmarkControllerFamily._();

/// Drives a fake benchmark run: a batch of requests that stream tokens with
/// live per-request and aggregate throughput. Cancelable mid-flight.
final class BenchmarkControllerProvider
    extends $NotifierProvider<BenchmarkController, BenchmarkRun> {
  /// Drives a fake benchmark run: a batch of requests that stream tokens with
  /// live per-request and aggregate throughput. Cancelable mid-flight.
  BenchmarkControllerProvider._({
    required BenchmarkControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'benchmarkControllerProvider',
         isAutoDispose: true,
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
    r'f7c011e4b41a8ddfbb476358459feb64345e3ca0';

/// Drives a fake benchmark run: a batch of requests that stream tokens with
/// live per-request and aggregate throughput. Cancelable mid-flight.

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
        isAutoDispose: true,
      );

  /// Drives a fake benchmark run: a batch of requests that stream tokens with
  /// live per-request and aggregate throughput. Cancelable mid-flight.

  BenchmarkControllerProvider call(String jobId) =>
      BenchmarkControllerProvider._(argument: jobId, from: this);

  @override
  String toString() => r'benchmarkControllerProvider';
}

/// Drives a fake benchmark run: a batch of requests that stream tokens with
/// live per-request and aggregate throughput. Cancelable mid-flight.

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
