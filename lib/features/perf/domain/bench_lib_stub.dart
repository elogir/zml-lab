import 'bench_lib_types.dart';

export 'bench_lib_types.dart';

/// Why the benchmark library can't be used here; null when it can.
String? benchLibProblem() => 'the benchmarker runs in the desktop app only';

BenchLibRun startBenchLib(
  BenchLibConfig config, {
  required void Function(String chunk) onCsv,
  required void Function(String line) onLog,
}) => throw UnsupportedError(benchLibProblem()!);
