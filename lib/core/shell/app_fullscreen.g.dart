// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_fullscreen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which surface (if any) is expanded to fill the window — the sidebar and the
/// screen's own chrome collapse away. Kept alive so the [AppShell] (which hides
/// the sidebar) and the screen (which hides its header and the other panes)
/// share one source of truth. Reset when the owning view is torn down so it
/// never lingers on other screens.

@ProviderFor(AppFullscreen)
final appFullscreenProvider = AppFullscreenProvider._();

/// Which surface (if any) is expanded to fill the window — the sidebar and the
/// screen's own chrome collapse away. Kept alive so the [AppShell] (which hides
/// the sidebar) and the screen (which hides its header and the other panes)
/// share one source of truth. Reset when the owning view is torn down so it
/// never lingers on other screens.
final class AppFullscreenProvider
    extends $NotifierProvider<AppFullscreen, FullscreenSurface?> {
  /// Which surface (if any) is expanded to fill the window — the sidebar and the
  /// screen's own chrome collapse away. Kept alive so the [AppShell] (which hides
  /// the sidebar) and the screen (which hides its header and the other panes)
  /// share one source of truth. Reset when the owning view is torn down so it
  /// never lingers on other screens.
  AppFullscreenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appFullscreenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appFullscreenHash();

  @$internal
  @override
  AppFullscreen create() => AppFullscreen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FullscreenSurface? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FullscreenSurface?>(value),
    );
  }
}

String _$appFullscreenHash() => r'1df6d9e4f037ed689580c4beb6fcf7530e639a78';

/// Which surface (if any) is expanded to fill the window — the sidebar and the
/// screen's own chrome collapse away. Kept alive so the [AppShell] (which hides
/// the sidebar) and the screen (which hides its header and the other panes)
/// share one source of truth. Reset when the owning view is torn down so it
/// never lingers on other screens.

abstract class _$AppFullscreen extends $Notifier<FullscreenSurface?> {
  FullscreenSurface? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FullscreenSurface?, FullscreenSurface?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FullscreenSurface?, FullscreenSurface?>,
              FullscreenSurface?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
