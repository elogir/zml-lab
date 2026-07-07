import 'dart:io';

/// Appends app diagnostics to /tmp/zml_lab.log. Each line is written
/// synchronously and flushed to disk, so a crash can't lose buffered lines —
/// which is the whole point. Log volume is low (errors + a few startup notes),
/// so per-line durability costs nothing noticeable.
abstract final class AppLog {
  static const path = '/tmp/zml_lab.log';
  static const _maxBytes = 2 * 1024 * 1024; // rotate past ~2 MB

  static File? _file;

  /// Opens the log for append (rotating a large existing file aside) and writes
  /// a session header. Best-effort — logging must never break startup.
  static void init() {
    try {
      final file = File(path);
      if (file.existsSync() && file.lengthSync() > _maxBytes) {
        try {
          file.renameSync('$path.1'); // keep one previous run's tail
        } catch (_) {}
      }
      _file = file;
      _line('==== session start pid=$pid ${Platform.operatingSystemVersion}');
    } catch (_) {
      _file = null;
    }
  }

  /// A plain diagnostic line.
  static void write(String message) => _line(message);

  /// An error with its stack.
  static void error(Object error, StackTrace? stack, {String? context}) {
    _line('ERROR${context == null ? '' : ' [$context]'}: $error');
    if (stack != null) _line(stack.toString());
  }

  static Future<void> flush() async {} // no-op: every write is already flushed

  static void _line(String message) {
    final file = _file;
    if (file == null) return;
    try {
      file.writeAsStringSync(
        '${DateTime.now().toIso8601String()} $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }
}
