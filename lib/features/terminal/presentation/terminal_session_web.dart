import 'dart:async';

import 'package:flterm/flterm.dart';
import 'package:flutter/widgets.dart';

/// Web stub: no PTY, so the pane shows a placeholder instead of a live
/// terminal. Mirrors the native API so the multiplexer compiles on both
/// platforms (execution itself is native-only).
class TerminalSession {
  TerminalSession({
    this.runCommand,
    this.initialCommand,
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    focusNode = FocusNode(debugLabel: 'terminal');
  }

  final String? runCommand;
  final String? initialCommand;

  // Created only if something asks for it: the web pane never renders a
  // TerminalView, and building a controller needs the wasm VT engine, which
  // may have failed to load.
  TerminalController? _controller;
  TerminalController get controller => _controller ??= TerminalController();
  late final FocusNode focusNode;

  bool get isLive => false;
  int? get pid => null;

  // No PTY on web, so the process never runs, exits or sets a title. These
  // mirror the native API so the multiplexer's wiring compiles.
  bool get hasExited => false;
  int? get exitCode => null;
  Future<int> get whenExited => Completer<int>().future; // never completes
  VoidCallback? onExit;
  String get title => '';
  VoidCallback? onTitleChanged;

  void sendInput(String data) {}

  void sendSignal() {}

  void sendKill() {}

  void dispose() {
    focusNode.dispose();
    _controller?.dispose();
  }
}
