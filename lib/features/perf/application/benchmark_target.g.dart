// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'benchmark_target.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the ad-hoc Benchmark tab's target. Keep-alive because the screen is
/// built from scratch on every visit — kept in the widget's State, the target
/// snapped back to 127.0.0.1:8000 (and to the Benchmark tool) each time you
/// navigated away and back, while the run itself survived under the `adhoc`
/// job id.

@ProviderFor(BenchmarkTargetController)
final benchmarkTargetControllerProvider = BenchmarkTargetControllerProvider._();

/// Holds the ad-hoc Benchmark tab's target. Keep-alive because the screen is
/// built from scratch on every visit — kept in the widget's State, the target
/// snapped back to 127.0.0.1:8000 (and to the Benchmark tool) each time you
/// navigated away and back, while the run itself survived under the `adhoc`
/// job id.
final class BenchmarkTargetControllerProvider
    extends $NotifierProvider<BenchmarkTargetController, BenchmarkTarget> {
  /// Holds the ad-hoc Benchmark tab's target. Keep-alive because the screen is
  /// built from scratch on every visit — kept in the widget's State, the target
  /// snapped back to 127.0.0.1:8000 (and to the Benchmark tool) each time you
  /// navigated away and back, while the run itself survived under the `adhoc`
  /// job id.
  BenchmarkTargetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'benchmarkTargetControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$benchmarkTargetControllerHash();

  @$internal
  @override
  BenchmarkTargetController create() => BenchmarkTargetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BenchmarkTarget value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BenchmarkTarget>(value),
    );
  }
}

String _$benchmarkTargetControllerHash() =>
    r'c281d7c235e4fdd40eaee284843d58ea79bb7ac7';

/// Holds the ad-hoc Benchmark tab's target. Keep-alive because the screen is
/// built from scratch on every visit — kept in the widget's State, the target
/// snapped back to 127.0.0.1:8000 (and to the Benchmark tool) each time you
/// navigated away and back, while the run itself survived under the `adhoc`
/// job id.

abstract class _$BenchmarkTargetController extends $Notifier<BenchmarkTarget> {
  BenchmarkTarget build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BenchmarkTarget, BenchmarkTarget>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BenchmarkTarget, BenchmarkTarget>,
              BenchmarkTarget,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
