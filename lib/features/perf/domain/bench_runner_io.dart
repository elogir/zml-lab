import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/execution/native_io.dart';

/// Expands a leading `~` to the home directory.
String expandUserPath(String path) {
  final home = Platform.environment['HOME'];
  if (home == null) return path;
  if (path == '~') return home;
  if (path.startsWith('~/')) return '$home${path.substring(1)}';
  return path;
}

bool directoryExists(String path) => Directory(path).existsSync();

/// The home directory written back as `~`, for display.
String abbreviateUserPath(String path) {
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) return path;
  if (path == home) return '~';
  if (path.startsWith('$home/')) return '~${path.substring(home.length)}';
  return path;
}

/// Why the ShareGPT dataset at [datasetPath] can't be used; null when it's
/// there.
Future<String?> datasetProblem(String datasetPath) async =>
    File(expandUserPath(datasetPath)).existsSync()
    ? null
    : 'ShareGPT dataset not found at $datasetPath';

/// The server's version, where it says (vLLM's GET /version); null otherwise.
Future<String?> fetchServerVersion({
  required String host,
  required int port,
  Duration timeout = const Duration(seconds: 2),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.get(host, port, '/version').timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != 200) return null;
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    final decoded = jsonDecode(body);
    return decoded is Map && decoded['version'] is String
        ? decoded['version'] as String
        : null;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// This machine, for a run's `meta.json`.
Map<String, String> clientInfo() => {
  'os': Platform.operatingSystemVersion,
  'host': Platform.localHostname,
};

/// The size of the file at [path] (`~` expanded), or null if there's none.
int? fileSize(String path) {
  final f = File(expandUserPath(path));
  return f.existsSync() ? f.lengthSync() : null;
}

/// GET /v1/models → model ids (vLLM needs a real model name; llmd ignores
/// it). Empty on any failure.
Future<List<String>> fetchModelIds({
  required String host,
  required int port,
  Duration timeout = const Duration(seconds: 4),
}) => listModels(ChatEndpoint.hostPort(host, port), timeout: timeout);

/// Writes [content] to ~/Downloads under [name].csv (deduplicating the file
/// name). Returns the destination path.
Future<String> exportTextFile({
  required String content,
  required String name,
}) async {
  final home = Platform.environment['HOME'] ?? '';
  final safe = name
      .replaceAll(RegExp(r'[/\\:]+'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  var dest = '$home/Downloads/$safe.csv';
  var n = 2;
  while (File(dest).existsSync()) {
    dest = '$home/Downloads/$safe ($n).csv';
    n++;
  }
  await File(dest).writeAsString(content);
  return dest;
}

/// Reveals a file in Finder (selected in its folder). If it isn't there,
/// opens the nearest folder that is.
Future<void> revealInFinder(String path) async {
  try {
    if (File(path).existsSync() || Directory(path).existsSync()) {
      await Process.run('/usr/bin/open', ['-R', path]);
      return;
    }
    var dir = Directory(path).parent;
    while (!dir.existsSync() && dir.parent.path != dir.path) {
      dir = dir.parent;
    }
    await Process.run('/usr/bin/open', [dir.path]);
  } catch (_) {}
}

/// Whether the perf runner works on this platform.
const benchRunnerAvailable = true;
