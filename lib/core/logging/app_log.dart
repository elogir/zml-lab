// App-level diagnostic log — a plain text file the app appends to so a crash
// (Dart exception, Flutter framework error, uncaught async error) leaves a
// trail even when the app was double-clicked and its stdout went nowhere.
// Native crashes (a segfault in a platform view, say) are NOT captured here —
// those land in macOS' ~/Library/Logs/DiagnosticReports.
//
// Native-only (dart:io); a no-op stub keeps the app building on web.
export 'app_log_stub.dart' if (dart.library.io) 'app_log_io.dart';
