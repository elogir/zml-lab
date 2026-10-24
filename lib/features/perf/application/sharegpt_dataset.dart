import 'dart:async';

// flutter_riverpod for `.select` (riverpod_annotation alone analyzes but
// doesn't build).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../settings/application/settings_controller.dart';
import '../domain/bench_runner.dart';
import '../domain/download.dart';
import '../domain/sharegpt.dart';

part 'sharegpt_dataset.g.dart';

enum DatasetPhase {
  /// Looking for the file.
  checking,

  /// Not there: offer the download.
  missing,
  downloading,

  /// Download stopped by an error (what was fetched is kept for a retry).
  failed,
  ready,
}

/// The ShareGPT dataset at the configured path, and its download.
class DatasetState {
  const DatasetState({
    required this.phase,
    required this.path,
    this.received = 0,
    this.total,
    this.bytesPerSecond,
    this.error,
  });

  final DatasetPhase phase;

  /// Where it is (or will be), as configured (may start with `~`).
  final String path;

  /// Bytes on disk so far — a resumable partial download counts.
  final int received;
  final int? total;

  /// Smoothed download speed; null until measured.
  final double? bytesPerSecond;
  final String? error;

  double? get fraction =>
      total == null || total == 0 ? null : (received / total!).clamp(0, 1);

  Duration? get remaining {
    final speed = bytesPerSecond;
    if (total == null || speed == null || speed <= 0) return null;
    return Duration(seconds: ((total! - received) / speed).ceil());
  }

  DatasetState copyWith({
    DatasetPhase? phase,
    int? received,
    int? total,
    double? bytesPerSecond,
    String? error,
  }) => DatasetState(
    phase: phase ?? this.phase,
    path: path,
    received: received ?? this.received,
    total: total ?? this.total,
    bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
    error: error,
  );
}

/// Keep-alive: a download carries on while you look at other tabs.
@Riverpod(keepAlive: true)
class ShareGptDataset extends _$ShareGptDataset {
  FileDownload? _download;
  StreamSubscription<DownloadProgress>? _progress;

  @override
  DatasetState build() {
    final path = ref.watch(
      settingsControllerProvider.select((s) => s.perfDatasetPath),
    );
    // A new path (Settings) rebuilds this: a download to the old one stops.
    ref.onDispose(() {
      _download?.cancel();
      _stop();
    });
    unawaited(_check(path));
    return DatasetState(phase: DatasetPhase.checking, path: path);
  }

  Future<void> _check(String path) async {
    final missing = await datasetProblem(path) != null;
    if (!ref.mounted || state.path != path) return;
    final partial = partialDownloadBytes(expandUserPath(path));
    state = DatasetState(
      phase: missing ? DatasetPhase.missing : DatasetPhase.ready,
      path: path,
      received: missing ? partial : ShareGpt.bytes,
      total: ShareGpt.bytes,
    );
  }

  /// Downloads (or resumes) the dataset to the configured path.
  void download() {
    if (state.phase == DatasetPhase.downloading ||
        state.phase == DatasetPhase.ready) {
      return;
    }
    final path = state.path;
    final download = startDownload(
      url: ShareGpt.url,
      dest: expandUserPath(path),
      sha256: ShareGpt.sha256,
    );
    _download = download;
    state = state.copyWith(phase: DatasetPhase.downloading);

    // Speed as a moving average, so the estimate doesn't jitter.
    DateTime? lastAt;
    int? lastBytes;
    double? speed;
    _progress = download.progress.listen((p) {
      final now = DateTime.now();
      if (lastAt != null) {
        final dt = now.difference(lastAt!).inMicroseconds / 1e6;
        if (dt > 0) {
          final instant = (p.received - lastBytes!) / dt;
          speed = speed == null ? instant : speed! * 0.8 + instant * 0.2;
        }
      }
      lastAt = now;
      lastBytes = p.received;
      state = state.copyWith(
        received: p.received,
        total: p.total,
        bytesPerSecond: speed,
      );
    });
    download.done.then(
      (_) {
        if (!identical(_download, download)) return;
        _stop();
        state = state.copyWith(
          phase: DatasetPhase.ready,
          received: ShareGpt.bytes,
        );
      },
      onError: (Object e) {
        if (!identical(_download, download)) return;
        _stop();
        state = state.copyWith(
          phase: DatasetPhase.failed,
          received: partialDownloadBytes(expandUserPath(path)),
          error: '$e',
        );
      },
    );
  }

  /// Stops the download; it resumes from here next time.
  void cancel() {
    if (state.phase != DatasetPhase.downloading) return;
    _download?.cancel();
    _stop();
    state = state.copyWith(phase: DatasetPhase.missing);
  }

  void _stop() {
    _progress?.cancel();
    _progress = null;
    _download = null;
  }
}
