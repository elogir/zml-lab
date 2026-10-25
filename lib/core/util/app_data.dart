// Where the app keeps its data (database, recorded runs). Native-only paths;
// a stub keeps the app building on web, where the database lives in the
// browser.
export 'app_data_stub.dart' if (dart.library.io) 'app_data_io.dart';
