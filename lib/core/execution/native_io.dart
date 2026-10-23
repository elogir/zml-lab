// Native-only IO (chat streaming for benchmarks, machine reachability check).
// Selected at compile time so the app still builds on web, where these degrade
// to no-ops.
export 'native_io_stub.dart' if (dart.library.io) 'native_io_impl.dart';
