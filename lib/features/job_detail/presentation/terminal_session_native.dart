import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flterm/flterm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pty/flutter_pty.dart';

/// Native terminal session: an flterm [TerminalController] wired to a real
/// local PTY.
///
/// By default it runs the user's login shell, fully interactive (nothing is
/// auto-run). Pass [runCommand] to instead run a specific command line — this
/// is how a launched job's process is hosted: the PTY *is* the job process, its
/// output is the job's live stdout/stderr, and [pid]/[onExit]/[exitCode]/
/// [sendSignal] let a supervisor track and control it.
class TerminalSession {
  TerminalSession({
    this.runCommand,
    this.initialCommand,
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    focusNode = FocusNode(debugLabel: 'terminal');
    controller.onTitleChanged = () {
      _title = controller.title;
      onTitleChanged?.call();
    };
    _start(workingDirectory, environment);
  }

  /// The command line to run instead of an interactive shell, or null for a
  /// plain login shell. Run through `$SHELL -l -c <command>` so PATH, aliases
  /// and profile are in effect (so e.g. `bazel` resolves).
  final String? runCommand;

  /// A command typed into the interactive shell as it starts (as if the user
  /// entered it) — e.g. `ssh <host>` so a remote job's terminal lands on its
  /// machine. Unlike [runCommand], the shell outlives the command: Ctrl+D out
  /// of the ssh drops back to the local prompt instead of closing the pane.
  /// Ignored when [runCommand] is set.
  final String? initialCommand;

  final TerminalController controller = TerminalController();
  late final FocusNode focusNode;

  Pty? _pty;
  StreamSubscription<Uint8List>? _sub;
  bool _exited = false;
  int? _exitCode;
  final Completer<int> _exitCompleter = Completer<int>();
  String _title = '';

  bool get isLive => _pty != null;

  /// The OS pid of the running process, or null if it never started.
  int? get pid => _pty?.pid;

  /// The window title the running program set via an OSC escape (empty until
  /// one is set). Used as the tab label. [onTitleChanged] fires when it moves.
  String get title => _title;
  VoidCallback? onTitleChanged;

  /// Whether the process has already exited (Ctrl+D, `exit`, a signal, or a
  /// crash). Lets a late-attached [onExit] fire immediately if it missed the
  /// event.
  bool get hasExited => _exited;

  /// The process exit code once [hasExited], else null. 0 = clean exit.
  int? get exitCode => _exitCode;

  /// Completes with the exit code when the process exits. Supervisors (the job
  /// executor) await this to move a job to exited/failed; unlike the
  /// single-slot [onExit] callback it can have many independent listeners.
  Future<int> get whenExited => _exitCompleter.future;

  /// Called once when the process exits, so the UI can close the pane. Cleared
  /// before we kill the PTY ourselves in [dispose] so our own teardown doesn't
  /// look like a user-initiated exit.
  VoidCallback? onExit;

  /// Sends SIGINT to the process without tearing down the controller, so its
  /// final output stays on screen. Used to kill a job gracefully (llmd shuts
  /// its server down cleanly on SIGINT) while keeping the terminal pane visible.
  void sendSignal() {
    try {
      _pty?.kill(ProcessSignal.sigint);
    } catch (_) {}
  }

  /// SIGKILL — the force escalation when [sendSignal] didn't take. Same
  /// keep-the-terminal contract; note it only reaches the PTY's direct child,
  /// so callers also kill by port for a server in its own process group.
  void sendKill() {
    try {
      _pty?.kill(ProcessSignal.sigkill);
    } catch (_) {}
  }

  void _start(String? workingDirectory, Map<String, String>? environment) {
    try {
      final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
      final pty = runCommand == null
          // -l: a login shell, like Terminal.app spawns. A GUI app only
          // inherits launchd's minimal PATH, and a non-login zsh never
          // sources /etc/zprofile or ~/.zprofile — so without this, brew,
          // go, ~/.local/bin etc. are all missing from interactive tabs.
          ? Pty.start(
              shell,
              arguments: ['-l'],
              columns: 80,
              rows: 24,
              workingDirectory: workingDirectory ?? Platform.environment['HOME'],
            )
          : Pty.start(
              shell,
              arguments: ['-l', '-c', runCommand!],
              columns: 80,
              rows: 24,
              workingDirectory: workingDirectory,
              environment: environment,
            );
      _pty = pty;
      controller
        ..onOutput = pty.write
        ..onResize = (cols, rows) => pty.resize(rows, cols);
      _sub = pty.output.listen(controller.write);
      if (runCommand == null && initialCommand != null) {
        // Queued in the PTY buffer; the shell echoes and runs it at its first
        // prompt, exactly as if typed.
        pty.write(Uint8List.fromList(utf8.encode('$initialCommand\n')));
      }
      pty.exitCode.then((code) {
        _exited = true;
        _exitCode = code;
        if (!_exitCompleter.isCompleted) _exitCompleter.complete(code);
        onExit?.call();
      });
    } catch (e) {
      debugPrint('Failed to start PTY: $e');
      _exited = true;
      _exitCode = -1;
      if (!_exitCompleter.isCompleted) _exitCompleter.complete(-1);
    }
  }

  void dispose() {
    onExit = null;
    onTitleChanged = null;
    _sub?.cancel();
    try {
      _pty?.kill();
    } catch (_) {}
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(-1);
    focusNode.dispose();
    controller.dispose();
  }
}
