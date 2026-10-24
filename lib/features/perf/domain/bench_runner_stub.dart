// Web stub: no dart:io (and no FFI), so the perf benchmarker can't run. Signatures mirror bench_runner_io.dart; everything degrades to
// "unavailable".

String expandUserPath(String path) => path;

String abbreviateUserPath(String path) => path;

bool directoryExists(String path) => false;

Future<String?> datasetProblem(String datasetPath) async =>
    'perf benchmarks need the desktop app';

Future<String?> fetchServerVersion({
  required String host,
  required int port,
  Duration timeout = const Duration(seconds: 2),
}) async => null;

Map<String, String> clientInfo() => const {};

int? fileSize(String path) => null;

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

const benchRunnerAvailable = false;
