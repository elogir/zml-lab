import 'dart:async';
import 'dart:convert';
import 'dart:io';

String _loginShell() => Platform.environment['SHELL'] ?? '/bin/zsh';

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

/// GET /v1/models → model ids, for prefilling the form (vLLM needs a real
/// model name; llmd ignores it). Empty on any failure.
Future<List<String>> fetchModelIds({
  required String host,
  required int port,
  Duration timeout = const Duration(seconds: 4),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.get(host, port, '/v1/models').timeout(timeout);
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    final decoded = jsonDecode(body);
    if (decoded is! Map) return const [];
    final data = decoded['data'];
    if (data is! List) return const [];
    return [
      for (final m in data)
        if (m is Map && m['id'] is String) m['id'] as String,
    ];
  } catch (_) {
    return const [];
  } finally {
    client.close(force: true);
  }
}

/// One small non-streaming chat completion, awaited fully — warms the server
/// up (first request often compiles/allocates) so the measured run starts
/// hot. Generous timeout for that reason. Throws on failure.
Future<void> warmupRequest({
  required String host,
  required int port,
  required String model,
  Duration timeout = const Duration(seconds: 300),
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.post(host, port, '/v1/chat/completions');
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'model': model.isEmpty ? 'zml_model' : model,
        'messages': [
          {'role': 'user', 'content': 'Warm-up. Reply with one word.'},
        ],
        'max_tokens': 16,
        'stream': false,
      }),
    );
    final response = await request.close().timeout(timeout);
    await response.drain<void>().timeout(timeout);
    if (response.statusCode >= 400) {
      throw Exception('warm-up request failed: HTTP ${response.statusCode}');
    }
  } finally {
    client.close(force: true);
  }
}

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

/// Reveals a file in Finder.
Future<void> revealInFinder(String path) async {
  try {
    await Process.run('/usr/bin/open', ['-R', path]);
  } catch (_) {}
}

/// Runs [command] in a login shell with [csv] on its stdin and [toolDir] as
/// the working directory (so `.read duckdb/report.sql` resolves), returning
/// its stdout. This is the CLI pipeline — `go run … | duckdb …` — with the
/// app's captured event stream standing in for the left side. Returns null on
/// a non-zero exit or any failure, so callers can fall back to their own
/// render.
Future<String?> runDuckdb({
  required String command,
  required String toolDir,
  required String csv,
}) async {
  try {
    final process = await Process.start(_loginShell(), [
      '-lc',
      command,
    ], workingDirectory: expandUserPath(toolDir));
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    process.stdin.write(csv);
    await process.stdin.close();
    final out = await stdoutFuture;
    await stderrFuture;
    final code = await process.exitCode;
    if (code != 0) return null;
    return out;
  } catch (_) {
    return null;
  }
}

/// Whether the perf runner works on this platform.
const benchRunnerAvailable = true;
