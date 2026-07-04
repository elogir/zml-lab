// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_fullscreen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the job's terminal/web area is expanded to fill the whole window —
/// the sidebar, detail header, and actions panel all collapse away. Kept alive
/// so the [AppShell] (which hides the sidebar) and the job detail screen (which
/// hides its own chrome) share one source of truth. Reset to false when the
/// terminal is torn down so it never lingers on other screens.

@ProviderFor(TerminalFullscreen)
final terminalFullscreenProvider = TerminalFullscreenProvider._();

/// Whether the job's terminal/web area is expanded to fill the whole window —
/// the sidebar, detail header, and actions panel all collapse away. Kept alive
/// so the [AppShell] (which hides the sidebar) and the job detail screen (which
/// hides its own chrome) share one source of truth. Reset to false when the
/// terminal is torn down so it never lingers on other screens.
final class TerminalFullscreenProvider
    extends $NotifierProvider<TerminalFullscreen, bool> {
  /// Whether the job's terminal/web area is expanded to fill the whole window —
  /// the sidebar, detail header, and actions panel all collapse away. Kept alive
  /// so the [AppShell] (which hides the sidebar) and the job detail screen (which
  /// hides its own chrome) share one source of truth. Reset to false when the
  /// terminal is torn down so it never lingers on other screens.
  TerminalFullscreenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terminalFullscreenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terminalFullscreenHash();

  @$internal
  @override
  TerminalFullscreen create() => TerminalFullscreen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$terminalFullscreenHash() =>
    r'd1bcbb3332969fbd3169a560ba399e5a4938eabe';

/// Whether the job's terminal/web area is expanded to fill the whole window —
/// the sidebar, detail header, and actions panel all collapse away. Kept alive
/// so the [AppShell] (which hides the sidebar) and the job detail screen (which
/// hides its own chrome) share one source of truth. Reset to false when the
/// terminal is torn down so it never lingers on other screens.

abstract class _$TerminalFullscreen extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
