// Native-only IO used by the job executor (free-port scan, endpoint health
// check). Selected at compile time so the app still builds on web, where these
// degrade to no-ops.
export 'native_io_stub.dart' if (dart.library.io) 'native_io_impl.dart';
