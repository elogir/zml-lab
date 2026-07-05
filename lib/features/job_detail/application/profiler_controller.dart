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
      _xprof?.dispose();
    });
    return const ProfilerRun();
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
      _xprof?.dispose();
      _xprof = TerminalSession(runCommand: _xprofCommand(machine, xprofPort));

      final serving = await _waitForXprof(xprofPort);
      if (!serving) {
        state = state.copyWith(
          phase: ProfilerPhase.failed,
          message: 'xprof did not start',
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
    _xprof?.dispose();
    _xprof = null;
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
