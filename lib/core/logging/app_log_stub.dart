/// Web stub: no filesystem, so the app log is a no-op (mirrors [AppLog]'s API).
abstract final class AppLog {
  static const path = '';

  static void init() {}
  static void write(String message) {}
  static void error(Object error, StackTrace? stack, {String? context}) {}
  static Future<void> flush() async {}
}
