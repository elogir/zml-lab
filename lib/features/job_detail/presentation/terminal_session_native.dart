import 'dart:async';
import 'dart:io';

import 'package:flterm/flterm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pty/flutter_pty.dart';

/// Native terminal session: an flterm [TerminalController] wired to a real
/// local PTY running the user's login shell. Fully interactive — nothing is
/// auto-run in it.
class TerminalSession {
  TerminalSession() {
    focusNode = FocusNode(debugLabel: 'terminal');
    _startShell();
  }

  final TerminalController controller = TerminalController();
  late final FocusNode focusNode;

  Pty? _pty;
  StreamSubscription<Uint8List>? _sub;

  bool get isLive => _pty != null;

  void _startShell() {
    try {
      final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
      final pty = Pty.start(
        shell,
        columns: 80,
        rows: 24,
        workingDirectory: Platform.environment['HOME'],
      );
      _pty = pty;
      controller
        ..onOutput = pty.write
        ..onResize = (cols, rows) => pty.resize(rows, cols);
      _sub = pty.output.listen(controller.write);
    } catch (e) {
      debugPrint('Failed to start shell PTY: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    try {
      _pty?.kill();
    } catch (_) {}
    focusNode.dispose();
    controller.dispose();
  }
}
