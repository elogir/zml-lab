// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profiler_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives profiling for a job, in two independent steps the UI exposes as
/// separate actions:
///
/// - [capture]: fire one request with the `x-zml-profiler` header so llmd
///   writes a trace to `/tmp/xprof` — works whether or not xprof is up.
/// - [launch]: serve the machine's `/tmp/xprof` with `uvx xprof` (over SSH
///   with a port-forward for a remote machine) and expose the URL — the
///   terminal opens it in a web tab. [reopen] re-opens that tab; [stop] kills
///   the server.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened or stopped.

@ProviderFor(ProfilerController)
final profilerControllerProvider = ProfilerControllerFamily._();

/// Drives profiling for a job, in two independent steps the UI exposes as
/// separate actions:
///
/// - [capture]: fire one request with the `x-zml-profiler` header so llmd
///   writes a trace to `/tmp/xprof` — works whether or not xprof is up.
/// - [launch]: serve the machine's `/tmp/xprof` with `uvx xprof` (over SSH
///   with a port-forward for a remote machine) and expose the URL — the
///   terminal opens it in a web tab. [reopen] re-opens that tab; [stop] kills
///   the server.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened or stopped.
final class ProfilerControllerProvider
    extends $NotifierProvider<ProfilerController, ProfilerRun> {
  /// Drives profiling for a job, in two independent steps the UI exposes as
  /// separate actions:
  ///
  /// - [capture]: fire one request with the `x-zml-profiler` header so llmd
  ///   writes a trace to `/tmp/xprof` — works whether or not xprof is up.
  /// - [launch]: serve the machine's `/tmp/xprof` with `uvx xprof` (over SSH
  ///   with a port-forward for a remote machine) and expose the URL — the
  ///   terminal opens it in a web tab. [reopen] re-opens that tab; [stop] kills
  ///   the server.
  ///
  /// Keep-alive (keyed by job id) so the xprof server keeps running while you
  /// navigate, and can be re-opened or stopped.
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
    r'e1e990e0795ce47b10d8472fecddd6b61d7eebd9';

/// Drives profiling for a job, in two independent steps the UI exposes as
/// separate actions:
///
/// - [capture]: fire one request with the `x-zml-profiler` header so llmd
///   writes a trace to `/tmp/xprof` — works whether or not xprof is up.
/// - [launch]: serve the machine's `/tmp/xprof` with `uvx xprof` (over SSH
///   with a port-forward for a remote machine) and expose the URL — the
///   terminal opens it in a web tab. [reopen] re-opens that tab; [stop] kills
///   the server.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened or stopped.

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

  /// Drives profiling for a job, in two independent steps the UI exposes as
  /// separate actions:
  ///
  /// - [capture]: fire one request with the `x-zml-profiler` header so llmd
  ///   writes a trace to `/tmp/xprof` — works whether or not xprof is up.
  /// - [launch]: serve the machine's `/tmp/xprof` with `uvx xprof` (over SSH
  ///   with a port-forward for a remote machine) and expose the URL — the
  ///   terminal opens it in a web tab. [reopen] re-opens that tab; [stop] kills
  ///   the server.
  ///
  /// Keep-alive (keyed by job id) so the xprof server keeps running while you
  /// navigate, and can be re-opened or stopped.

  ProfilerControllerProvider call(String jobId) =>
      ProfilerControllerProvider._(argument: jobId, from: this);

  @override
  String toString() => r'profilerControllerProvider';
}

/// Drives profiling for a job, in two independent steps the UI exposes as
/// separate actions:
///
/// - [capture]: fire one request with the `x-zml-profiler` header so llmd
///   writes a trace to `/tmp/xprof` — works whether or not xprof is up.
/// - [launch]: serve the machine's `/tmp/xprof` with `uvx xprof` (over SSH
///   with a port-forward for a remote machine) and expose the URL — the
///   terminal opens it in a web tab. [reopen] re-opens that tab; [stop] kills
///   the server.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened or stopped.

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
