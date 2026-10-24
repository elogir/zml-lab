import 'run_recorder_types.dart';

export 'run_recorder_types.dart';

// Web stub: perf runs are recorded by the desktop app only.

String runsDir() => '';

String? debugRunsDir;

String runFilePath(String runId) => '';

bool runFileExists(String runId) => false;

Future<void> deleteRun(String runId) async {}

class RunSpool {
  RunSpool._();

  static Future<RunSpool> create(String runId) async =>
      throw UnsupportedError('runs are recorded by the desktop app');

  String get runId => '';

  void addEvents(String csvChunk) {}

  void addChipSample(int tsNs, List<ChipReading> devices) {}

  Future<String?> finish(Map<String, Object?> meta) async => null;

  Future<void> discard() async {}
}

Future<void> exportRun({
  required String runFile,
  required Map<String, Object?> meta,
  required String out,
}) async => throw UnsupportedError('runs are exported by the desktop app');

Future<Map<String, Object?>?> readRunMeta(String runFile) async => null;
