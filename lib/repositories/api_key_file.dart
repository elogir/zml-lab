// Where saved endpoints' API keys live: a private file on native, the session
// only on web (no file system). Selected at compile time so the app still
// builds on web.
export 'api_key_file_stub.dart' if (dart.library.io) 'api_key_file_io.dart';
