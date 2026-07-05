import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/execution/job_executor.dart';
import '../../../core/execution/native_io.dart';
import '../../../models/machine.dart';
import '../presentation/terminal_session.dart';

part 'profiler_controller.g.dart';

enum ProfilerPhase { idle, capturing, launching, ready, failed }

/// State of a profiler run: capture a trace, launch xprof, then expose its URL.
class ProfilerRun {
  const ProfilerRun({
    this.phase = ProfilerPhase.idle,
    this.message,
    this.url,
    this.openToken = 0,
  });

  final ProfilerPhase phase;
  final String? message;

  /// The xprof web UI URL, set once it's serving.
  final String? url;

  /// Bumped each time the xprof tab should (re)open — so the terminal opens it
  /// on start and on an explicit re-open, but NOT merely because the view was
  /// remounted (navigating away and back).
  final int openToken;

  bool get isBusy =>
      phase == ProfilerPhase.capturing || phase == ProfilerPhase.launching;
  bool get isReady => phase == ProfilerPhase.ready && url != null;
}

/// Runs a profiler capture for a job and serves the trace with `xprof`.
///
/// Steps: (1) fire one request with the `x-zml-profiler` header so llmd writes a
/// trace to `/tmp/xprof`; (2) launch `uvx xprof -l /tmp/xprof -p <port>` on the
/// job's machine (over SSH with a port-forward for a remote one); (3) wait for
/// it to serve, then expose the URL — the terminal opens it in a web tab.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened or stopped.
@Riverpod(keepAlive: true)
class ProfilerController extends _$ProfilerController {
  static const _logdir = '/tmp/xprof';

  TerminalSession? _xprof;
  String? _lastUrl;
  int _openToken = 0;

  @override
  ProfilerRun build(String jobId) {
    // A failure message describes the process it ran against — once the
    // executor spawns a replacement, clear it back to idle instead of showing
    // a stale error against the fresh server. (Plain addListener: the executor
    // is a ChangeNotifier; its provider state never changes.)
    final executor = ref.watch(jobExecutorProvider);
    void onExecutorChanged() {
      if (state.phase == ProfilerPhase.failed) state = const ProfilerRun();
    }

    executor.addListener(onExecutorChanged);
    ref.onDispose(() {
      executor.removeListener(onExecutorChanged);
      _xprof?.dispose();
    });
    return const ProfilerRun();
  }

  Future<void> run({
    required String host,
    required int port,
    required Machine machine,
  }) async {
    if (state.isBusy) return;
    try {
      state = const ProfilerRun(
        phase: ProfilerPhase.capturing,
        message: 'capturing trace…',
      );
      await runProfileRequest(host, port);

      state = const ProfilerRun(
        phase: ProfilerPhase.launching,
        message: 'starting xprof…',
      );
      final xprofPort = await findFreePort(start: 8791, end: 8891, avoid: {port});
      _xprof?.dispose();
      _xprof = TerminalSession(runCommand: _xprofCommand(machine, xprofPort));

      final serving = await _waitForXprof(xprofPort);
      if (!serving) {
        state = const ProfilerRun(
          phase: ProfilerPhase.failed,
          message: 'xprof did not start',
        );
        return;
      }
      _lastUrl = 'http://localhost:$xprofPort';
      state = ProfilerRun(
        phase: ProfilerPhase.ready,
        url: _lastUrl,
        openToken: ++_openToken,
      );
    } catch (e) {
      state = ProfilerRun(phase: ProfilerPhase.failed, message: '$e');
    }
  }

  /// Re-open the xprof tab (if the user closed it) — bumps the open token so the
  /// terminal opens it again, without re-capturing.
  void reopen() {
    if (_lastUrl == null) return;
    state = ProfilerRun(
      phase: ProfilerPhase.ready,
      url: _lastUrl,
      openToken: ++_openToken,
    );
  }

  /// Stop the xprof server and reset to idle.
  void stop() {
    _xprof?.dispose();
    _xprof = null;
    _lastUrl = null;
    state = const ProfilerRun();
  }

  String _xprofCommand(Machine machine, int port) {
    final xprof = 'uvx xprof -l $_logdir -p $port';
    if (machine.isLocal) return xprof;
    // Remote: forward localhost:port → remote:port and run xprof on the remote
    // (which reads the remote's /tmp/xprof).
    final ssh = StringBuffer('ssh -tt -L $port:localhost:$port');
    if (machine.sshPort != 22) ssh.write(' -p ${machine.sshPort}');
    if (machine.sshKey != null && machine.sshKey!.isNotEmpty) {
      ssh.write(" -i '${machine.sshKey}'");
    }
    ssh.write(" ${machine.sshTarget} '$xprof'");
    return ssh.toString();
  }

  /// Polls the forwarded xprof port until its HTTP server answers.
  Future<bool> _waitForXprof(int port) async {
    for (var i = 0; i < 60; i++) {
      if (_xprof?.hasExited ?? true) return false; // process died
      final probe = await probeEndpoint('127.0.0.1', port, path: '/');
      if (probe.error == null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }
}
