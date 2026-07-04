import 'package:flterm/flterm.dart';
import 'package:flutter/widgets.dart';

/// Web stub: no PTY. The controller exists (flterm supports web) but no shell
/// is attached, so the pane shows a placeholder instead of a live terminal.
class TerminalSession {
  TerminalSession() {
    focusNode = FocusNode(debugLabel: 'terminal');
  }

  final TerminalController controller = TerminalController();
  late final FocusNode focusNode;

  bool get isLive => false;

  // No PTY on web, so the shell never exits. These mirror the native API so
  // the multiplexer's exit-closes-pane wiring compiles on both platforms.
  bool get hasExited => false;
  VoidCallback? onExit;

  void dispose() {
    focusNode.dispose();
    controller.dispose();
  }
}
