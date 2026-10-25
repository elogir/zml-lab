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

  /// A newer release is out but not downloaded: with auto update off, it
  /// downloads when "Update to …" is clicked (also where a failed download
  /// lands, to be retried).
  available,
  downloading,

  /// A newer build is unpacked beside the app, waiting to be swapped in.
  ready,
  failed,
}

/// Where self-updating stands, for the sidebar's update button and Settings.
@immutable
class UpdateStatus {
  const UpdateStatus(
    this.phase, {
    this.version,
    this.progress = 0,
    this.installing = false,
    this.error,
    this.checkedAt,
  });

  final UpdatePhase phase;

  /// The release available, downloading or ready.
  final AppVersion? version;

  /// Download progress, 0–1.
  final double progress;

  /// The download was started from the sidebar: the app restarts into the
  /// update once it's in.
  final bool installing;

  final String? error;

  /// When GitHub last answered.
  final DateTime? checkedAt;
}

/// Checks GitHub for new releases (shortly after launch, then every few
/// hours). With auto update on, a new release downloads and stages beside the
/// app right away, the swap is armed so it goes in when the app quits, and
/// "Restart to update" installs it sooner. With it off, the sidebar offers
/// "Update to …", which downloads it and then restarts into it.
@Riverpod(keepAlive: true)
class Updater extends _$Updater {
  final UpdateInstaller? _installer = UpdateInstaller.forThisApp();
  final AppVersion? _current = AppVersion.tryParse(appVersion);
  Timer? _timer;

  /// The check or download in flight.
  Future<void>? _busy;

  /// The newer release found but not downloaded yet.
  UpdateRelease? _available;

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
    ref.listen(settingsControllerProvider.select((s) => s.autoUpdate), (_, on) {
      final release = _available;
      if (on && release != null && state.phase == UpdatePhase.available) {
        unawaited(_run(() => _download(release)));
      }
      _syncSwap();
    });
    _timer = Timer(_firstCheck, _tick);

    // A build staged in an earlier session (whose swap failed, or that was
    // never restarted into) is still good to go.
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

  /// One check or download at a time: a second caller gets the one in flight.
  Future<void> _run(Future<void> Function() job) =>
      _busy ??= job().whenComplete(() => _busy = null);

  /// Looks for a newer release, and with auto update on downloads it — what
  /// "Check now" runs too. A known release stays offered through later checks.
  Future<void> check() => _run(_check);

  Future<void> _check() async {
    final installer = _installer;
    final current = _current;
    if (installer == null || current == null) return;
    final quiet =
        state.phase == UpdatePhase.ready ||
        state.phase == UpdatePhase.available;
    if (!quiet) {
      state = UpdateStatus(UpdatePhase.checking, checkedAt: state.checkedAt);
    }
    final UpdateRelease? release;
    try {
      release = await installer.fetchLatest();
    } catch (e) {
      debugPrint('update check failed: $e');
      if (quiet) return;
      state = UpdateStatus(
        UpdatePhase.failed,
        error: e is UpdateException ? e.message : '$e',
        checkedAt: state.checkedAt,
      );
      return;
    }
    final checkedAt = DateTime.now();
    if (release == null || !(release.version > current)) {
      _available = null;
      state = _settled(checkedAt);
      return;
    }
    if (installer.stagedVersion == release.version) {
      _available = null;
      state = UpdateStatus(
        UpdatePhase.ready,
        version: release.version,
        checkedAt: checkedAt,
      );
      _syncSwap();
      return;
    }
    _available = release;
    if (ref.read(settingsControllerProvider).autoUpdate) {
      await _download(release, checkedAt: checkedAt);
    } else {
      state = UpdateStatus(
        UpdatePhase.available,
        version: release.version,
        checkedAt: checkedAt,
      );
    }
  }

  /// Downloads and stages [release]. On failure it stays available, with the
  /// reason, for a retry.
  Future<void> _download(
    UpdateRelease release, {
    DateTime? checkedAt,
    bool installing = false,
  }) async {
    final installer = _installer;
    if (installer == null) return;
    checkedAt ??= state.checkedAt;
    _disarm(); // its staged build is about to be replaced
    UpdateStatus downloading(double progress) => UpdateStatus(
      UpdatePhase.downloading,
      version: release.version,
      progress: progress,
      installing: installing,
      checkedAt: checkedAt,
    );
    var shown = -1;
    state = downloading(0);
    try {
      await installer.stage(
        release,
        onProgress: (fraction) {
          final percent = (fraction * 100).floor();
          if (percent == shown) return;
          shown = percent;
          state = downloading(fraction);
        },
      );
    } catch (e) {
      debugPrint('update download failed: $e');
      state = UpdateStatus(
        UpdatePhase.available,
        version: release.version,
        error: e is UpdateException ? e.message : '$e',
        checkedAt: checkedAt,
      );
      return;
    }
    _available = null;
    state = UpdateStatus(
      UpdatePhase.ready,
      version: release.version,
      checkedAt: checkedAt,
    );
    _syncSwap();
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

  /// The sidebar's update button: downloads the update if it isn't yet, then
  /// restarts into it. [confirmed] is what the terminals were running when the
  /// user agreed to restart; if a download let something else start, it stops
  /// at "Restart to update" instead of killing it.
  Future<void> install({List<String> confirmed = const []}) async {
    await _busy; // a check in flight decides what there is to install
    final release = _available;
    if (state.phase == UpdatePhase.available && release != null) {
      await _run(() => _download(release, installing: true));
      if (state.phase != UpdatePhase.ready) return;
      final busy = await busyTerminals();
      if (!busy.every(confirmed.contains)) return;
    }
    await restartNow();
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
