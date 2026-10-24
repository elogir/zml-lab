// The perf benchmarker: the Go library in native/zmlbench, built and bundled
// by hook/build.dart and driven over FFI. Native only: the web stub reports
// it unavailable.
export 'bench_lib_stub.dart' if (dart.library.ffi) 'bench_lib_native.dart';
