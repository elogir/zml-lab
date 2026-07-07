// Native-only plumbing for the perf benchmark: building and running the
// monorepo's Go benchmarker, the warm-up request, and CSV file handling.
// Selected at compile time so the app still builds on web, where the perf
// runner degrades to "unavailable".
export 'bench_runner_stub.dart' if (dart.library.io) 'bench_runner_io.dart';
