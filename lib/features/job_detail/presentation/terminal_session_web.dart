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

  void dispose() {
    focusNode.dispose();
    controller.dispose();
  }
}
