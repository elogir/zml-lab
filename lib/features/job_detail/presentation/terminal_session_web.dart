import 'dart:async';

import 'package:flterm/flterm.dart';
import 'package:flutter/widgets.dart';

/// Web stub: no PTY. The controller exists (flterm supports web) but no process
/// is attached, so the pane shows a placeholder instead of a live terminal.
/// Mirrors the native API so the multiplexer and the job executor compile on
/// both platforms (execution itself is native-only).
class TerminalSession {
  TerminalSession({
    this.runCommand,
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    focusNode = FocusNode(debugLabel: 'terminal');
  }

  final String? runCommand;

  final TerminalController controller = TerminalController();
  late final FocusNode focusNode;

  bool get isLive => false;
  int? get pid => null;

  // No PTY on web, so the process never runs, exits or sets a title. These
  // mirror the native API so the multiplexer's and executor's wiring compiles.
  bool get hasExited => false;
  int? get exitCode => null;
  Future<int> get whenExited => Completer<int>().future; // never completes
  VoidCallback? onExit;
  String get title => '';
  VoidCallback? onTitleChanged;

  void sendSignal() {}

  void dispose() {
    focusNode.dispose();
    controller.dispose();
  }
}
