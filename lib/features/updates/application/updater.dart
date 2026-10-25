import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../settings/application/settings_controller.dart';
import '../../terminal/presentation/terminal_session.dart';
import '../domain/update_installer.dart';
import '../domain/update_release.dart';

part 'updater.g.dart';

enum UpdatePhase {
  /// A local build, or an OS without release builds: nothing to update.
  unavailable,
  idle,
  checking,
  downloading,

  /// A newer build is unpacked beside the app, waiting to be swapped in.
  ready,
  failed,
}

/// Where self-updating stands, for the sidebar's restart button and Settings.
@immutable
class UpdateStatus {
  const UpdateStatus(
    this.phase, {
    this.version,
    this.progress = 0,
    this.error,
    this.checkedAt,
  });

  final UpdatePhase phase;

  /// The release downloading or ready.
  final AppVersion? version;

  /// Download progress, 0–1.
  final double progress;

  final String? error;

  /// When GitHub last answered.
  final DateTime? checkedAt;
}

/// Checks GitHub for new releases (shortly after launch, then every few
/// hours), downloads and stages them beside the app, and offers "Restart to
/// update". With auto update on it also arms the swap, so a staged build goes
/// in when the app quits.
@Riverpod(keepAlive: true)
class Updater extends _$Updater {
  final UpdateInstaller? _installer = UpdateInstaller.forThisApp();
  final AppVersion? _current = AppVersion.tryParse(appVersion);
  Timer? _timer;
  bool _checking = false;

  /// The armed swap script's pid.
  Future<int>? _waiter;

  static const _firstCheck = Duration(seconds: 10);
  static const _interval = Duration(hours: 6);

  @override
  UpdateStatus build() {
    final installer = _installer;
    final current = _current;
    if (installer == null || current == null) {
      return const UpdateStatus(UpdatePhase.unavailable);
    }
    ref.onDispose(() => _timer?.cancel());
    ref.listen(
      settingsControllerProvider.select((s) => s.autoUpdate),
      (_, _) => _syncSwap(),
    );
    _timer = Timer(_firstCheck, _tick);

    // A build staged in an earlier session (with auto update off, or one
    // whose swap failed) is still good to go.
    final staged = installer.stagedVersion;
    if (staged != null && staged > current) {
      Future.microtask(_syncSwap);
      return UpdateStatus(UpdatePhase.ready, version: staged);
    }
    if (staged != null) unawaited(installer.discard());
    return const UpdateStatus(UpdatePhase.idle);
  }

  void _tick() {
    _timer = Timer(_interval, _tick);
    unawaited(check());
  }

  /// Looks for a newer release and stages it — what "Check now" runs too. A
  /// staged build stays ready through later checks.
  Future<void> check() async {
    final installer = _installer;
    final current = _current;
    if (installer == null || current == null || _checking) return;
    _checking = true;
    if (state.phase != UpdatePhase.ready) {
      state = UpdateStatus(UpdatePhase.checking, checkedAt: state.checkedAt);
    }
    try {
      final release = await installer.fetchLatest();
      final checkedAt = DateTime.now();
      if (release == null || !(release.version > current)) {
        state = _settled(checkedAt);
        return;
      }
      if (installer.stagedVersion == release.version) {
        state = UpdateStatus(
          UpdatePhase.ready,
          version: release.version,
          checkedAt: checkedAt,
        );
        _syncSwap();
        return;
      }
      _disarm(); // its staged build is about to be replaced
      var shown = -1;
      state = UpdateStatus(
        UpdatePhase.downloading,
        version: release.version,
        checkedAt: checkedAt,
      );
      await installer.stage(
        release,
        onProgress: (fraction) {
          final percent = (fraction * 100).floor();
          if (percent == shown) return;
          shown = percent;
          state = UpdateStatus(
            UpdatePhase.downloading,
            version: release.version,
            progress: fraction,
            checkedAt: checkedAt,
          );
        },
      );
      state = UpdateStatus(
        UpdatePhase.ready,
        version: release.version,
        checkedAt: checkedAt,
      );
      _syncSwap();
    } catch (e) {
      debugPrint('update check failed: $e');
      final settled = _settled(state.checkedAt);
      state = settled.phase == UpdatePhase.ready
          ? settled
          : UpdateStatus(
              UpdatePhase.failed,
              error: e is UpdateException ? e.message : '$e',
              checkedAt: state.checkedAt,
            );
    } finally {
      _checking = false;
    }
  }

  /// Ready if a newer build is staged, else idle.
  UpdateStatus _settled(DateTime? checkedAt) {
    final staged = _installer?.stagedVersion;
    return staged != null && staged > _current!
        ? UpdateStatus(UpdatePhase.ready, version: staged, checkedAt: checkedAt)
        : UpdateStatus(UpdatePhase.idle, checkedAt: checkedAt);
  }

  /// What's running in the terminals, which a restart would stop.
  Future<List<String>> busyTerminals() async {
    final jobs = await Future.wait([
      for (final session in TerminalSession.running) session.foregroundJob(),
    ]);
    return jobs.nonNulls.toList();
  }

  /// Quits and relaunches into the staged build.
  Future<void> restartNow() async {
    final installer = _installer;
    if (installer == null || state.phase != UpdatePhase.ready) return;
    // One swap at a time: the install-on-quit script would race this one.
    final waiter = _waiter;
    _waiter = null;
    if (waiter != null) {
      final pid = await waiter.catchError((_) => 0);
      if (pid > 0) installer.disarm(pid);
    }
    await installer.restartInto();
  }

  /// Arms the swap while a build is staged and auto update is on; disarms it
  /// otherwise.
  void _syncSwap() {
    final installer = _installer;
    if (installer == null) return;
    final armed =
        state.phase == UpdatePhase.ready &&
        ref.read(settingsControllerProvider).autoUpdate;
    if (!armed) return _disarm();
    if (_waiter != null) return;
    final waiter = installer.armSwap();
    _waiter = waiter;
    waiter.catchError((Object e) {
      debugPrint('arming the update swap failed: $e');
      if (identical(_waiter, waiter)) _waiter = null;
      return 0;
    });
  }

  void _disarm() {
    final waiter = _waiter;
    _waiter = null;
    waiter?.then((pid) {
      if (pid > 0) _installer?.disarm(pid);
    }, onError: (_) {});
  }
}
