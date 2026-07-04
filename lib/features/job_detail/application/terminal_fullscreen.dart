import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terminal_fullscreen.g.dart';

/// Whether the job's terminal/web area is expanded to fill the whole window —
/// the sidebar, detail header, and actions panel all collapse away. Kept alive
/// so the [AppShell] (which hides the sidebar) and the job detail screen (which
/// hides its own chrome) share one source of truth. Reset to false when the
/// terminal is torn down so it never lingers on other screens.
@Riverpod(keepAlive: true)
class TerminalFullscreen extends _$TerminalFullscreen {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void exit() => state = false;
}
