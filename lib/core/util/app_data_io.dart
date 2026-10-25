import 'dart:io';

/// Where ZML-Lab keeps its data — the database, recorded runs:
/// `~/Library/Application Support/ZML-Lab` on macOS, the platform's
/// equivalent elsewhere. Not ~/Documents: macOS guards that folder per app
/// and asks again whenever the app's signature changes.
String appDataDir() {
  final env = Platform.environment;
  if (Platform.isWindows) return '${env['APPDATA']}\\ZML-Lab';
  if (Platform.isLinux) {
    return '${env['XDG_DATA_HOME'] ?? '${env['HOME']}/.local/share'}/zml-lab';
  }
  return '${env['HOME']}/Library/Application Support/ZML-Lab';
}

/// The database file, its folder created if missing.
Future<String> appDatabasePath() async {
  final dir = await Directory(appDataDir()).create(recursive: true);
  return '${dir.path}${Platform.pathSeparator}zml_lab.sqlite';
}

/// The folder builds before 0.1.4 kept the database in (as
/// `zml_lab.sqlite`), where importing it starts looking.
String legacyDatabaseDir() => '${Platform.environment['HOME']}/Documents';
