import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_fullscreen.g.dart';

/// The surfaces that can expand to fill the whole window.
enum FullscreenSurface { terminal, perf }

/// Which surface (if any) is expanded to fill the window — the sidebar and the
/// screen's own chrome collapse away. Kept alive so the [AppShell] (which hides
/// the sidebar) and the screen (which hides its header and the other panes)
/// share one source of truth. Reset when the owning view is torn down so it
/// never lingers on other screens.
@Riverpod(keepAlive: true)
class AppFullscreen extends _$AppFullscreen {
  @override
  FullscreenSurface? build() => null;

  void toggle(FullscreenSurface surface) =>
      state = state == surface ? null : surface;

  void exit() => state = null;

  /// Drops fullscreen only if [surface] holds it — so one view tearing down
  /// doesn't kick another out of fullscreen.
  void exitIf(FullscreenSurface surface) {
    if (state == surface) state = null;
  }
}
