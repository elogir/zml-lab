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
  bool _exited = false;

  bool get isLive => _pty != null;

  /// Whether the shell process has already exited (Ctrl+D, `exit`, or a
  /// crash). Lets a late-attached [onExit] fire immediately if it missed the
  /// event.
  bool get hasExited => _exited;

  /// Called once when the shell process exits, so the UI can close the pane.
  /// Cleared before we kill the PTY ourselves in [dispose] so our own teardown
  /// doesn't look like a user-initiated exit.
  VoidCallback? onExit;

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
      pty.exitCode.then((_) {
        _exited = true;
        onExit?.call();
      });
    } catch (e) {
      debugPrint('Failed to start shell PTY: $e');
    }
  }

  void dispose() {
    onExit = null;
    _sub?.cancel();
    try {
      _pty?.kill();
    } catch (_) {}
    focusNode.dispose();
    controller.dispose();
  }
}
