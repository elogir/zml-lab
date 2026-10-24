// Native-only plumbing for the perf benchmark: the dataset check, the
// warm-up request, and CSV file handling. (The benchmarker itself is the
// FFI library in bench_lib.dart.)
// Selected at compile time so the app still builds on web, where the perf
// runner degrades to "unavailable".
export 'bench_runner_stub.dart' if (dart.library.io) 'bench_runner_io.dart';
