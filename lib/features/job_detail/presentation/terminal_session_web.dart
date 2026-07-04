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

  // No PTY on web, so the shell never exits and no program sets a title. These
  // mirror the native API so the multiplexer's wiring compiles on both.
  bool get hasExited => false;
  VoidCallback? onExit;
  String get title => '';
  VoidCallback? onTitleChanged;

  void dispose() {
    focusNode.dispose();
    controller.dispose();
  }
}
