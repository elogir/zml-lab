import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/job_detail/presentation/terminal_session.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../models/enums.dart';
import '../../models/job.dart';
import '../../models/machine.dart';
import '../../repositories/job_repository.dart';
import '../../repositories/machine_repository.dart';
import 'native_io.dart';

part 'job_executor.g.dart';

/// Substitutes the job's port into the command wherever `$PORT`/`${PORT}`
/// appears, so the launched server binds the port the app tracks (status dot,
/// test-endpoint, benchmark all use it).
String applyPortTemplate(String command, int port) => command
    .replaceAll(r'${PORT}', '$port')
    .replaceAll(r'$PORT', '$port');

/// A resolved, ready-to-run invocation: the command line to feed a local shell,
/// plus the working directory and environment (null for remote — those are
/// folded into the SSH command instead).
class _Invocation {
  _Invocation(this.command, {this.workingDirectory, this.environment});
  final String command;
  final String? workingDirectory;
  final Map<String, String>? environment;
}

/// Owns the live process behind each running job and keeps the persisted job
/// status in sync with it. This is the local/remote execution boundary: a local
/// machine runs the command directly through a PTY; a remote one runs the *same*
/// command wrapped in `ssh`. Kept alive (not tied to any widget) so a job keeps
/// running while you navigate around the app.
///
/// A job's lifetime is tied to the app: the process runs as a child in a PTY, so
/// closing zml-lab closes the PTY → SIGHUP → the process dies. Nothing survives a
/// restart, so there's no reattach — on startup any job the DB still marks active
/// is simply recorded as stopped ([markStaleStopped]).
///
/// The live process is a [TerminalSession] (the same PTY primitive the terminal
/// uses), so the job-detail terminal can *borrow* it to show the real stdout.
/// A [ChangeNotifier] so the terminal can swap to the new session on restart.
class JobExecutor extends ChangeNotifier {
  JobExecutor(this._jobs, this._machines);

  final JobRepository _jobs;
  final MachineRepository _machines;

  /// Periodically re-checks running jobs' endpoints so a job whose server dies
  /// or hangs stops showing as running.
  Timer? _monitor;

  /// jobId → its process session. Kept even after the process exits so the
  /// terminal can still show the final output; replaced on relaunch, disposed
  /// on delete or app shutdown.
  final Map<String, TerminalSession> _sessions = {};
  final Map<String, Timer> _healthTimers = {};

  /// jobs we SIGINT'd ourselves, so their non-zero exit reads as a clean stop
  /// rather than a crash.
  final Set<String> _killed = {};

  /// The process session for [jobId] (live or just-exited), or null if this
  /// executor never launched it. The terminal borrows this to display real
  /// output.
  TerminalSession? sessionFor(String jobId) => _sessions[jobId];

  /// Whether a live (not-yet-exited) process is supervised for [jobId].
  bool isRunning(String jobId) {
    final s = _sessions[jobId];
    return s != null && !s.hasExited;
  }

  /// Whether [kill] was already requested for a still-live process — the next
  /// [kill] escalates to SIGKILL, and the UI labels the action accordingly.
  bool killRequested(String jobId) =>
      _killed.contains(jobId) && isRunning(jobId);

  /// Launches [job] on [machine]: spawns the process, records `starting` + pid +
  /// startedAt, then probes the port (TCP connect — silent, no request for the
  /// server to log) to promote it to `running`, and watches for exit to record
  /// `exited`/`failed`.
  Future<void> launch(Job job, Machine machine) async {
    if (isRunning(job.id)) return; // already up
    final prior = _sessions[job.id]; // a leftover dead session, if any
    _killed.remove(job.id);
    await _spawnAndSupervise(job, machine);
    _disposeSessionLater(prior); // usually null for a fresh job id
  }

  /// Stops the current process, waits for it to release the port, then launches
  /// it again from the same spec. The terminal swaps to the new process's output
  /// (via [notifyListeners]); the old, still-displayed session is disposed only
  /// after that swap so its native view isn't torn down mid-use.
  Future<void> restart(Job job, Machine machine) async {
    final old = _sessions[job.id];
    if (old != null && !old.hasExited) {
      _killed.add(job.id); // graceful: its non-zero exit isn't a crash
      if (machine.isLocal) {
        old.sendSignal();
      } else {
        // Remote: SIGINT the server by port on the host — our ssh dying never
        // reaches it (see [kill]). The ssh session then unwinds by itself.
        await _killRemotePort(machine, job.port);
      }
      // Wait for the port to actually free before relaunching on it.
      final code = await old.whenExited.timeout(
        const Duration(seconds: 6),
        onTimeout: () => -1,
      );
      if (code == -1 && !old.hasExited) {
        // Didn't unwind (remote kill missed?) — cut our end and move on.
        old.sendSignal();
        await old.whenExited.timeout(
          const Duration(seconds: 3),
          onTimeout: () => -1,
        );
      }
    } else if (!machine.isLocal) {
      // No live session, but a previous server may have orphaned on the host
      // (it outlives our ssh) — clear the job's port before rebinding it.
      await _killRemotePort(machine, job.port);
    }
    _healthTimers.remove(job.id)?.cancel();
    _killed.remove(job.id);
    await _spawnAndSupervise(job, machine); // replaces _sessions[job.id]
    _disposeSessionLater(old);
  }

  /// Spawns the process for [job] on [machine], records `starting` + pid +
  /// startedAt, and wires exit + health supervision. Replaces any existing
  /// session in the map (the caller disposes the old one) and notifies so a
  /// mounted terminal can adopt the new session.
  Future<void> _spawnAndSupervise(Job job, Machine machine) async {
    final inv = _buildInvocation(job, machine);
    final session = TerminalSession(
      runCommand: inv.command,
      workingDirectory: inv.workingDirectory,
      environment: inv.environment,
    );
    _sessions[job.id] = session;
    session.whenExited.then((code) => _onExit(job.id, code));
    _startHealthPoll(job, machine);
    notifyListeners();
    await _jobs.upsertJob(
      job.copyWith(
        status: JobStatus.starting,
        pid: session.pid,
        startedAt: DateTime.now(),
      ),
    );
  }

  /// Disposes [session] after the current frame, so a terminal still displaying
  /// it has a chance to swap away first (disposing a mounted flterm view
  /// crashes). No-op for null.
  void _disposeSessionLater(TerminalSession? session) {
    if (session == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => session.dispose());
  }

  /// On startup, any job the DB still marks active (`running`/`starting`) is
  /// stale — its process died with the previous app session — so record it as
  /// stopped. No probing: nothing survives a close.
  Future<void> markStaleStopped() async {
    final jobs = await _jobs.allJobs();
    for (final job in jobs) {
      if (job.status.isActive) {
        await _jobs.updateJobStatus(job.id, JobStatus.exited, clearPid: true);
      }
    }
  }

  /// Stops every running job — called when the app is closing so nothing is left
  /// behind. SIGINTs our PTYs, and reaches each server directly by port — the
  /// PTY signal alone can miss it (locally it's a grandchild in its own process
  /// group; remotely it's a child of the host's bazel daemon). All graceful;
  /// llmd shuts down on SIGINT.
  Future<void> stopAll() async {
    for (final s in _sessions.values) {
      if (!s.hasExited) s.sendSignal();
    }
    final jobs = await _jobs.allJobs();
    for (final job in jobs) {
      if (!job.status.isActive) continue;
      final machine = await _machines.machineById(job.machineId);
      if (machine == null || machine.isLocal) {
        await killPortListeners(job.port);
      } else {
        await _killRemotePort(machine, job.port);
      }
    }
  }

  /// Stops a running job with SIGINT (llmd shuts down cleanly), keeping its final
  /// output on screen. The [_onExit] handler records the stopped status.
  /// Calling it again while the process is still alive escalates to SIGKILL —
  /// both to our PTY child and by port, which is what actually reaches a
  /// server sitting in its own process group.
  ///
  /// Local: signal our own process tree. Remote: SIGINT the server *by port on
  /// the host* — under `bazel run` it's a child of the remote bazel daemon,
  /// so killing our ssh/tty never reaches it. The ssh session then unwinds on
  /// its own as the server exits (its shutdown output streams into the
  /// terminal); if it doesn't within 10s, cut our end.
  Future<void> kill(Job job, Machine machine) async {
    final session = _sessions[job.id];
    if (session != null && !session.hasExited) {
      final force = _killed.contains(job.id); // second press → SIGKILL
      _killed.add(job.id); // its non-zero exit reads as a clean stop
      notifyListeners(); // arms the UI's force-kill label
      if (machine.isLocal) {
        if (force) {
          session.sendKill();
          await killPortListeners(job.port, force: true);
        } else {
          session.sendSignal();
        }
      } else {
        await _killRemotePort(machine, job.port, force: force);
        if (force) {
          session.sendKill(); // cut our ssh end too, don't wait for unwind
        } else {
          unawaited(
            session.whenExited.timeout(const Duration(seconds: 10),
                onTimeout: () {
              if (!session.hasExited) session.sendSignal();
              return -1;
            }),
          );
        }
      }
      return;
    }
    // No live handle — record the stop directly; a remote server can outlive
    // our ssh session, so also clear the job's port on the host.
    if (!machine.isLocal) await _killRemotePort(machine, job.port);
    await _jobs.updateJobStatus(job.id, JobStatus.exited, clearPid: true);
  }

  Future<void> _killRemotePort(Machine machine, int port, {bool force = false}) =>
      killRemotePortListeners(
        target: machine.sshTarget,
        port: port,
        sshPort: machine.sshPort,
        identityFile: machine.sshKey,
        force: force,
      );

  /// Starts the periodic health monitor. Runs for the app's life; calling
  /// again (settings change) reschedules at the new interval.
  void startMonitoring(Duration interval) {
    _monitor?.cancel();
    _monitor = Timer.periodic(interval, (_) => _checkRunningJobs());
  }

  Future<void> _checkRunningJobs() async {
    final jobs = await _jobs.allJobs();
    for (final job in jobs) {
      if (job.status != JobStatus.running) continue;
      if (_killed.contains(job.id)) continue; // we're stopping it; skip
      final machine = await _machines.machineById(job.machineId);
      final host = (machine != null && !machine.isLocal)
          ? machine.address
          : '127.0.0.1';
      final up = await checkHealth(host, job.port);
      if (!up) {
        // A running server that stopped answering — mark it failed so the
        // dashboard stops showing green.
        await _jobs.updateJobStatus(job.id, JobStatus.failed, clearPid: true);
      }
    }
  }

  /// Removes a job entirely: stops its process, drops its session and row.
  Future<void> remove(String jobId) async {
    _healthTimers.remove(jobId)?.cancel();
    _sessions.remove(jobId)?.dispose();
    _killed.remove(jobId);
    await _jobs.deleteJob(jobId);
  }

  void _startHealthPoll(Job job, Machine machine) {
    final host = machine.isLocal ? '127.0.0.1' : machine.address;
    _healthTimers[job.id]?.cancel();
    _healthTimers[job.id] = Timer.periodic(
      const Duration(milliseconds: 1500),
      (timer) async {
        final session = _sessions[job.id];
        if (session == null || session.hasExited) {
          timer.cancel();
          _healthTimers.remove(job.id);
          return;
        }
        final up = await checkHealth(host, job.port);
        // Re-check liveness after the await — it may have exited meanwhile.
        final current = _sessions[job.id];
        if (up && current != null && !current.hasExited) {
          timer.cancel();
          _healthTimers.remove(job.id);
          await _jobs.updateJobStatus(job.id, JobStatus.running);
        }
      },
    );
  }

  Future<void> _onExit(String jobId, int code) async {
    _healthTimers.remove(jobId)?.cancel();
    // Keep the (now dead) session so the terminal still shows the final output.
    final graceful = code == 0 || _killed.remove(jobId);
    await _jobs.updateJobStatus(
      jobId,
      graceful ? JobStatus.exited : JobStatus.failed,
      clearPid: true,
    );
  }

  _Invocation _buildInvocation(Job job, Machine machine) {
    final command = applyPortTemplate(job.command, job.port);
    final env = {for (final e in job.env) e.key: e.value};
    final workingDir = (job.workingDir == null || job.workingDir!.trim().isEmpty)
        ? null
        : job.workingDir!.trim();

    if (machine.isLocal) {
      return _Invocation(
        command,
        workingDirectory: workingDir == null ? null : expandUser(workingDir),
        environment: env.isEmpty ? null : env,
      );
    }

    // Remote: run the same command over SSH, folding cd + env into the remote
    // shell (the local PTY just runs `ssh`).
    final remote = StringBuffer();
    // `ssh host 'cmd'` runs a non-login, non-interactive shell that sources
    // neither .zprofile nor .zshrc, so the user's PATH additions are absent and
    // tools like bazel / uv installed under ~/.local/bin (or Homebrew) aren't
    // found. Put the usual locations back on PATH. $HOME/$PATH expand on the
    // remote (the whole command is single-quoted to ssh, so nothing expands
    // here).
    remote.write(
      r'export PATH="$HOME/.local/bin:$HOME/bin:/opt/homebrew/bin:'
      r'/usr/local/bin:$PATH" && ',
    );
    if (workingDir != null) {
      remote.write('cd ${_shQuoteRemotePath(workingDir)} && ');
    }
    for (final e in env.entries) {
      remote.write('export ${e.key}=${_shSingleQuote(e.value)} && ');
    }
    remote.write(command);

    final ssh = StringBuffer('ssh -tt');
    if (machine.sshPort != 22) ssh.write(' -p ${machine.sshPort}');
    if (machine.sshKey != null && machine.sshKey!.isNotEmpty) {
      ssh.write(' -i ${_shSingleQuote(machine.sshKey!)}');
    }
    ssh.write(' ${machine.sshTarget} ${_shSingleQuote(remote.toString())}');
    return _Invocation(ssh.toString());
  }

  /// Wraps [s] in single quotes for a POSIX shell, escaping embedded quotes.
  static String _shSingleQuote(String s) => "'${s.replaceAll("'", r"'\''")}'";

  /// Quotes a path for the *remote* shell, leaving a leading `~` unquoted so
  /// the remote expands it to its own home — `cd '~/x'` would be a literal
  /// tilde. We can't expand it locally (the remote home isn't ours).
  static String _shQuoteRemotePath(String path) {
    if (path == '~') return '~';
    if (path.startsWith('~/')) {
      return '~/${_shSingleQuote(path.substring(2))}';
    }
    return _shSingleQuote(path);
  }

  @override
  void dispose() {
    _monitor?.cancel();
    for (final t in _healthTimers.values) {
      t.cancel();
    }
    _healthTimers.clear();
    for (final s in _sessions.values) {
      s.dispose();
    }
    _sessions.clear();
    super.dispose();
  }
}

@Riverpod(keepAlive: true)
JobExecutor jobExecutor(Ref ref) {
  final executor = JobExecutor(
    ref.watch(jobRepositoryProvider),
    ref.watch(machineRepositoryProvider),
  );
  // Health-check cadence follows the setting — listen (not watch), so a
  // change reschedules the timer without recreating the executor (which owns
  // the live process sessions).
  executor.startMonitoring(
    Duration(
      seconds: ref.read(settingsControllerProvider).healthIntervalSeconds,
    ),
  );
  ref.listen(settingsControllerProvider, (prev, next) {
    if (prev?.healthIntervalSeconds != next.healthIntervalSeconds) {
      executor.startMonitoring(Duration(seconds: next.healthIntervalSeconds));
    }
  });
  ref.onDispose(executor.dispose);
  return executor;
}
