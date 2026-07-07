// Web stub: no dart:io, so the perf benchmarker (a local Go process) can't
// run. Signatures mirror bench_runner_io.dart; everything degrades to
// "unavailable".

String expandUserPath(String path) => path;

Future<String?> benchPreflight({
  required String toolDir,
  required String datasetPath,
}) async => 'perf benchmarks need the desktop app';

Future<String> buildBenchmarker({required String toolDir}) async =>
    throw UnsupportedError('perf benchmarks need the desktop app');

class BenchProcess {
  BenchProcess._();

  Future<int> get exited async => -1;
  void interrupt() {}
  void kill() {}
}

Future<BenchProcess> startBenchmarker({
  required String binPath,
  required String toolDir,
  required List<String> args,
  required void Function(String chunk) onCsv,
  required void Function(String line) onStderr,
}) async => throw UnsupportedError('perf benchmarks need the desktop app');

Future<List<String>> fetchModelIds({
  required String host,
  required int port,
  Duration timeout = const Duration(seconds: 4),
}) async => const [];

Future<void> warmupRequest({
  required String host,
  required int port,
  required String model,
  Duration timeout = const Duration(seconds: 300),
}) async {}

Future<String> exportTextFile({
  required String content,
  required String name,
}) async => throw UnsupportedError('export needs the desktop app');

Future<void> revealInFinder(String path) async {}

Future<String?> runDuckdb({
  required String command,
  required String toolDir,
  required String csv,
}) async => null;

const benchRunnerAvailable = false;
