// The self-updater's file and process work (download, unpack, swap the app).
// Selected at compile time so the app still builds on web, where nothing
// updates itself.
export 'update_installer_stub.dart'
    if (dart.library.io) 'update_installer_native.dart';
