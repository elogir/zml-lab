// Large file downloads (the ShareGPT dataset) with progress, resume and a
// checksum. Native only: on web the stub reports downloads unsupported.
export 'download_stub.dart' if (dart.library.io) 'download_io.dart';
