// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profiler_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs a profiler capture for a job and serves the trace with `xprof`.
///
/// Steps: (1) fire one request with the `x-zml-profiler` header so llmd writes a
/// trace to `/tmp/xprof`; (2) launch `uvx xprof -l /tmp/xprof -p <port>` on the
/// job's machine (over SSH with a port-forward for a remote one); (3) wait for
/// it to serve, then expose the URL — the terminal opens it in a web tab.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened.

@ProviderFor(ProfilerController)
final profilerControllerProvider = ProfilerControllerFamily._();

/// Runs a profiler capture for a job and serves the trace with `xprof`.
///
/// Steps: (1) fire one request with the `x-zml-profiler` header so llmd writes a
/// trace to `/tmp/xprof`; (2) launch `uvx xprof -l /tmp/xprof -p <port>` on the
/// job's machine (over SSH with a port-forward for a remote one); (3) wait for
/// it to serve, then expose the URL — the terminal opens it in a web tab.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened.
final class ProfilerControllerProvider
    extends $NotifierProvider<ProfilerController, ProfilerRun> {
  /// Runs a profiler capture for a job and serves the trace with `xprof`.
  ///
  /// Steps: (1) fire one request with the `x-zml-profiler` header so llmd writes a
  /// trace to `/tmp/xprof`; (2) launch `uvx xprof -l /tmp/xprof -p <port>` on the
  /// job's machine (over SSH with a port-forward for a remote one); (3) wait for
  /// it to serve, then expose the URL — the terminal opens it in a web tab.
  ///
  /// Keep-alive (keyed by job id) so the xprof server keeps running while you
  /// navigate, and can be re-opened.
  ProfilerControllerProvider._({
    required ProfilerControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profilerControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profilerControllerHash();

  @override
  String toString() {
    return r'profilerControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProfilerController create() => ProfilerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfilerRun value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfilerRun>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfilerControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profilerControllerHash() =>
    r'3b0e31a09c200d8e9f9a2ecb5e7ea94ccee28d3c';

/// Runs a profiler capture for a job and serves the trace with `xprof`.
///
/// Steps: (1) fire one request with the `x-zml-profiler` header so llmd writes a
/// trace to `/tmp/xprof`; (2) launch `uvx xprof -l /tmp/xprof -p <port>` on the
/// job's machine (over SSH with a port-forward for a remote one); (3) wait for
/// it to serve, then expose the URL — the terminal opens it in a web tab.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened.

final class ProfilerControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProfilerController,
          ProfilerRun,
          ProfilerRun,
          ProfilerRun,
          String
        > {
  ProfilerControllerFamily._()
    : super(
        retry: null,
        name: r'profilerControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Runs a profiler capture for a job and serves the trace with `xprof`.
  ///
  /// Steps: (1) fire one request with the `x-zml-profiler` header so llmd writes a
  /// trace to `/tmp/xprof`; (2) launch `uvx xprof -l /tmp/xprof -p <port>` on the
  /// job's machine (over SSH with a port-forward for a remote one); (3) wait for
  /// it to serve, then expose the URL — the terminal opens it in a web tab.
  ///
  /// Keep-alive (keyed by job id) so the xprof server keeps running while you
  /// navigate, and can be re-opened.

  ProfilerControllerProvider call(String jobId) =>
      ProfilerControllerProvider._(argument: jobId, from: this);

  @override
  String toString() => r'profilerControllerProvider';
}

/// Runs a profiler capture for a job and serves the trace with `xprof`.
///
/// Steps: (1) fire one request with the `x-zml-profiler` header so llmd writes a
/// trace to `/tmp/xprof`; (2) launch `uvx xprof -l /tmp/xprof -p <port>` on the
/// job's machine (over SSH with a port-forward for a remote one); (3) wait for
/// it to serve, then expose the URL — the terminal opens it in a web tab.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened.

abstract class _$ProfilerController extends $Notifier<ProfilerRun> {
  late final _$args = ref.$arg as String;
  String get jobId => _$args;

  ProfilerRun build(String jobId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfilerRun, ProfilerRun>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfilerRun, ProfilerRun>,
              ProfilerRun,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
