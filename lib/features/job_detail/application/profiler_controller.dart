import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/execution/job_executor.dart';
import '../../../core/execution/native_io.dart';
import '../../../models/machine.dart';
import '../presentation/terminal_session.dart';

part 'profiler_controller.g.dart';

enum ProfilerPhase { idle, launching, ready, failed }

/// Profiler state for a job — two independent halves:
/// capturing a trace (one profiled request) and serving traces with xprof.
class ProfilerRun {
  const ProfilerRun({
    this.capturing = false,
    this.captureMessage,
    this.phase = ProfilerPhase.idle,
    this.message,
    this.url,
    this.openToken = 0,
  });

  /// True while a profiled request is in flight.
  final bool capturing;

  /// Status line for the capture tile ('capturing…', 'trace captured', error).
  final String? captureMessage;

  /// The xprof server's lifecycle.
  final ProfilerPhase phase;

  /// Status line for the xprof tile while launching / after failing.
  final String? message;

  /// The xprof web UI URL, set once it's serving.
  final String? url;

  /// Bumped each time the xprof tab should (re)open — so the terminal opens it
  /// on start and on an explicit re-open, but NOT merely because the view was
  /// remounted (navigating away and back).
  final int openToken;

  bool get isReady => phase == ProfilerPhase.ready && url != null;

  static const _unset = Object();

  ProfilerRun copyWith({
    bool? capturing,
    Object? captureMessage = _unset,
    ProfilerPhase? phase,
    Object? message = _unset,
    Object? url = _unset,
    int? openToken,
  }) {
    return ProfilerRun(
      capturing: capturing ?? this.capturing,
      captureMessage: identical(captureMessage, _unset)
          ? this.captureMessage
          : captureMessage as String?,
      phase: phase ?? this.phase,
      message: identical(message, _unset) ? this.message : message as String?,
      url: identical(url, _unset) ? this.url : url as String?,
      openToken: openToken ?? this.openToken,
    );
  }
}

/// Drives profiling for a job, in two independent steps the UI exposes as
/// separate actions:
///
/// - [capture]: fire one request with the `x-zml-profiler` header so llmd
///   writes a trace to `/tmp/xprof` — works whether or not xprof is up.
/// - [launch]: serve the machine's `/tmp/xprof` with `uvx xprof` (over SSH
///   with a port-forward for a remote machine) and expose the URL — the
///   terminal opens it in a web tab. [reopen] re-opens that tab; [stop] kills
///   the server.
///
/// Keep-alive (keyed by job id) so the xprof server keeps running while you
/// navigate, and can be re-opened or stopped.
@Riverpod(keepAlive: true)
class ProfilerController extends _$ProfilerController {
  static const _logdir = '/tmp/xprof';

  TerminalSession? _xprof;
  int? _xprofPort;
  Machine? _xprofMachine;
  String? _lastUrl;
  int _openToken = 0;

  @override
  ProfilerRun build(String jobId) {
    // Failure/status messages describe the process they ran against — once the
    // executor spawns a replacement, clear them instead of showing stale
    // errors against the fresh server. A ready xprof stays: it serves trace
    // files, not the live process. (Plain addListener: the executor is a
    // ChangeNotifier; its provider state never changes.)
    final executor = ref.watch(jobExecutorProvider);
    void onExecutorChanged() {
      final s = state;
      final failed = s.phase == ProfilerPhase.failed;
      if (s.captureMessage == null && !failed) return;
      state = failed
          ? s.copyWith(
              captureMessage: null,
              phase: ProfilerPhase.idle,
              message: null,
            )
          : s.copyWith(captureMessage: null);
    }

    executor.addListener(onExecutorChanged);
    ref.onDispose(() {
      executor.removeListener(onExecutorChanged);
      _killXprof();
    });
    return const ProfilerRun();
  }

  /// Kills the current xprof for real. Disposing the PTY only reaches its
  /// session-leader shell/ssh — the uv-spawned python is a grandchild in its
  /// own process group that survives and keeps the port (same reason llmd
  /// under `bazel run` needs a port-kill) — so also SIGINT whatever LISTENs
  /// on the xprof port, locally or on the remote.
  void _killXprof() {
    _xprof?.dispose();
    _xprof = null;
    final port = _xprofPort;
    final machine = _xprofMachine;
    _xprofPort = null;
    _xprofMachine = null;
    if (port == null || machine == null) return;
    if (machine.isLocal) {
      killPortListeners(port);
    } else {
      killRemotePortListeners(
        target: machine.sshTarget,
        port: port,
        sshPort: machine.sshPort,
        identityFile: machine.sshKey,
      );
    }
  }

  /// Send one profiled request (llmd writes the trace to [_logdir]).
  /// Independent of xprof — captures land whether or not it's serving.
  Future<void> capture({required String host, required int port}) async {
    if (state.capturing) return;
    state = state.copyWith(capturing: true, captureMessage: 'capturing…');
    try {
      await runProfileRequest(host, port);
      state = state.copyWith(capturing: false, captureMessage: 'trace captured');
    } catch (e) {
      state = state.copyWith(capturing: false, captureMessage: '$e');
    }
  }

  /// Start xprof serving [_logdir] on the job's machine, then expose its URL.
  Future<void> launch({required Machine machine, required int jobPort}) async {
    if (state.phase == ProfilerPhase.launching) return;
    state = state.copyWith(
      phase: ProfilerPhase.launching,
      message: 'starting xprof…',
      url: null,
    );
    try {
      final xprofPort =
          await findFreePort(start: 8791, end: 8891, avoid: {jobPort});
      _killXprof();
      _xprof = TerminalSession(runCommand: _xprofCommand(machine, xprofPort));
      _xprofPort = xprofPort;
      _xprofMachine = machine;

      final serving = await _waitForXprof(xprofPort);
      if (!serving) {
        // Distinguish a dead process from a slow one, then reap it — a
        // slow-starting xprof would otherwise bind the port later and linger.
        final exited = _xprof?.hasExited ?? true;
        _killXprof();
        state = state.copyWith(
          phase: ProfilerPhase.failed,
          message: exited ? 'xprof exited' : 'xprof not serving after 60s',
        );
        return;
      }
      _lastUrl = 'http://localhost:$xprofPort';
      state = state.copyWith(
        phase: ProfilerPhase.ready,
        message: null,
        url: _lastUrl,
        openToken: ++_openToken,
      );
    } catch (e) {
      state = state.copyWith(phase: ProfilerPhase.failed, message: '$e');
    }
  }

  /// Re-open the xprof tab (if the user closed it) — bumps the open token so the
  /// terminal opens it again, without relaunching.
  void reopen() {
    if (_lastUrl == null) return;
    state = state.copyWith(
      phase: ProfilerPhase.ready,
      url: _lastUrl,
      openToken: ++_openToken,
    );
  }

  /// Stop the xprof server and reset its half to idle.
  void stop() {
    _killXprof();
    _lastUrl = null;
    state = state.copyWith(
      phase: ProfilerPhase.idle,
      message: null,
      url: null,
    );
  }

  String _xprofCommand(Machine machine, int port) {
    // mkdir first so xprof can serve a job that hasn't captured yet.
    final xprof = 'mkdir -p $_logdir && uvx xprof -l $_logdir -p $port';
    if (machine.isLocal) return xprof;
    // Remote: forward localhost:port → remote:port and run xprof on the remote
    // (which reads the remote's /tmp/xprof). Non-interactive ssh doesn't
    // source .profile, so ~/.local/bin — where uv installs — isn't on PATH;
    // prepend it explicitly ($HOME expands on the remote, not here).
    final remote = 'PATH="\$HOME/.local/bin:\$PATH" $xprof';
    final ssh = StringBuffer('ssh -tt -L $port:localhost:$port');
    if (machine.sshPort != 22) ssh.write(' -p ${machine.sshPort}');
    if (machine.sshKey != null && machine.sshKey!.isNotEmpty) {
      ssh.write(" -i '${machine.sshKey}'");
    }
    ssh.write(" ${machine.sshTarget} '$remote'");
    return ssh.toString();
  }

  /// Polls the forwarded xprof port until its HTTP server answers. Generous
  /// deadline (60s): a cold `uvx xprof` (fresh uv env / cold FS cache) can
  /// take well over 30s before it starts serving.
  Future<bool> _waitForXprof(int port) async {
    for (var i = 0; i < 120; i++) {
      if (_xprof?.hasExited ?? true) return false; // process died
      final probe = await probeEndpoint('127.0.0.1', port, path: '/');
      if (probe.error == null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }
}
