// The Go benchmarker, embedded as a shared library (built and
// bundled by hook/build.dart) and driven over FFI. Native only: the web stub
// reports it unavailable.
export 'bench_lib_stub.dart' if (dart.library.ffi) 'bench_lib_native.dart';
