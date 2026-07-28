// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perf_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs the monorepo's Go benchmarker (tools/benchmark) against a job's
/// endpoint and turns its CSV event stream into live charts and a final
/// report. The tool does the load generation; the app only consumes its
/// native output (see PerfAccumulator for the report.sql parity).

@ProviderFor(PerfController)
final perfControllerProvider = PerfControllerFamily._();

/// Runs the monorepo's Go benchmarker (tools/benchmark) against a job's
/// endpoint and turns its CSV event stream into live charts and a final
/// report. The tool does the load generation; the app only consumes its
/// native output (see PerfAccumulator for the report.sql parity).
final class PerfControllerProvider
    extends $NotifierProvider<PerfController, PerfRun> {
  /// Runs the monorepo's Go benchmarker (tools/benchmark) against a job's
  /// endpoint and turns its CSV event stream into live charts and a final
  /// report. The tool does the load generation; the app only consumes its
  /// native output (see PerfAccumulator for the report.sql parity).
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

String _$perfControllerHash() => r'65798f2ea3de23d190f747d6b8642f81ac655d90';

/// Runs the monorepo's Go benchmarker (tools/benchmark) against a job's
/// endpoint and turns its CSV event stream into live charts and a final
/// report. The tool does the load generation; the app only consumes its
/// native output (see PerfAccumulator for the report.sql parity).

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

  /// Runs the monorepo's Go benchmarker (tools/benchmark) against a job's
  /// endpoint and turns its CSV event stream into live charts and a final
  /// report. The tool does the load generation; the app only consumes its
  /// native output (see PerfAccumulator for the report.sql parity).

  PerfControllerProvider call(String jobId) =>
      PerfControllerProvider._(argument: jobId, from: this);

  @override
  String toString() => r'perfControllerProvider';
}

/// Runs the monorepo's Go benchmarker (tools/benchmark) against a job's
/// endpoint and turns its CSV event stream into live charts and a final
/// report. The tool does the load generation; the app only consumes its
/// native output (see PerfAccumulator for the report.sql parity).

abstract class _$PerfController extends $Notifier<PerfRun> {
  late final _$args = ref.$arg as String;
  String get jobId => _$args;

  PerfRun build(String jobId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PerfRun, PerfRun>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PerfRun, PerfRun>,
              PerfRun,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
