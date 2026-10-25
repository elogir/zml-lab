// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perf_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs the bundled Go benchmarker (native/zmlbench, over FFI — see
/// bench_lib.dart) against a job's endpoint and turns its CSV event stream
/// into live charts and a final report. The library does the load
/// generation; the app computes the statistics (PerfAccumulator).

@ProviderFor(PerfController)
final perfControllerProvider = PerfControllerFamily._();

/// Runs the bundled Go benchmarker (native/zmlbench, over FFI — see
/// bench_lib.dart) against a job's endpoint and turns its CSV event stream
/// into live charts and a final report. The library does the load
/// generation; the app computes the statistics (PerfAccumulator).
final class PerfControllerProvider
    extends $NotifierProvider<PerfController, PerfRun> {
  /// Runs the bundled Go benchmarker (native/zmlbench, over FFI — see
  /// bench_lib.dart) against a job's endpoint and turns its CSV event stream
  /// into live charts and a final report. The library does the load
  /// generation; the app computes the statistics (PerfAccumulator).
  PerfControllerProvider._({
    required PerfControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'perfControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$perfControllerHash();

  @override
  String toString() {
    return r'perfControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PerfController create() => PerfController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PerfRun value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PerfRun>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PerfControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$perfControllerHash() => r'8ca05ce5c21a6a624710d7ece7cdddf94c87fb8d';

/// Runs the bundled Go benchmarker (native/zmlbench, over FFI — see
/// bench_lib.dart) against a job's endpoint and turns its CSV event stream
/// into live charts and a final report. The library does the load
/// generation; the app computes the statistics (PerfAccumulator).

final class PerfControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PerfController,
          PerfRun,
          PerfRun,
          PerfRun,
          String
        > {
  PerfControllerFamily._()
    : super(
        retry: null,
        name: r'perfControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Runs the bundled Go benchmarker (native/zmlbench, over FFI — see
  /// bench_lib.dart) against a job's endpoint and turns its CSV event stream
  /// into live charts and a final report. The library does the load
  /// generation; the app computes the statistics (PerfAccumulator).

  PerfControllerProvider call(String jobId) =>
      PerfControllerProvider._(argument: jobId, from: this);

  @override
  String toString() => r'perfControllerProvider';
}

/// Runs the bundled Go benchmarker (native/zmlbench, over FFI — see
/// bench_lib.dart) against a job's endpoint and turns its CSV event stream
/// into live charts and a final report. The library does the load
/// generation; the app computes the statistics (PerfAccumulator).

abstract class _$PerfController extends $Notifier<PerfRun> {
  late final _$args = ref.$arg as String;
  String get jobId => _$args;

  PerfRun build(String jobId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PerfRun, PerfRun>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PerfRun, PerfRun>,
              PerfRun,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
