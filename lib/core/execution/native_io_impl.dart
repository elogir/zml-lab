import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// SIGINTs whatever is listening on [port] on loopback ([force] escalates to
/// SIGKILL). Used to stop a job's server on app close: the process (e.g. llmd
/// under `bazel run`) is a grandchild in its own process group that a
/// PTY-close SIGHUP misses, but it does bind the port we track, so we can
/// find and signal it directly. Best-effort.
Future<void> killPortListeners(int port, {bool force = false}) async {
  try {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    final r = await Process.run(shell, [
      '-lc',
      'lsof -nP -iTCP:$port -sTCP:LISTEN -t',
    ]);
    for (final line in (r.stdout as String).split('\n')) {
      final pid = int.tryParse(line.trim());
      if (pid != null) {
        try {
          Process.killPid(
            pid,
            force ? ProcessSignal.sigkill : ProcessSignal.sigint,
          );
        } catch (_) {}
      }
    }
  } catch (_) {}
}

/// SIGINTs whatever is LISTENing on [port] on a remote host, over ssh — the
/// remote mirror of [killPortListeners]. A remote job's server outlives its
/// ssh/tty (under `bazel run` it's a child of the detached bazel daemon, so
/// killing our ssh never reaches it); the port is the one handle we own.
/// Uses `fuser -k -INT` (psmisc, stock on Ubuntu/Debian). Best-effort with a
/// hard timeout so app close can't hang on a dead host.
Future<void> killRemotePortListeners({
  required String target,
  required int port,
  int sshPort = 22,
  String? identityFile,
  bool force = false,
  Duration timeout = const Duration(seconds: 8),
}) async {
  try {
    await Process.run('/usr/bin/ssh', [
      '-o', 'BatchMode=yes',
      '-o', 'ConnectTimeout=5',
      if (sshPort != 22) ...['-p', '$sshPort'],
      if (identityFile != null && identityFile.isNotEmpty)
        ...['-i', identityFile],
      target,
      'fuser -k -${force ? 'KILL' : 'INT'} $port/tcp',
    ]).timeout(timeout);
  } catch (_) {}
}

/// Expands a leading `~` to the user's home directory, so a working directory
/// like `~/Documents/monorepo` resolves (PTY chdir doesn't expand tildes).
String expandUser(String path) {
  if (path == '~') return Platform.environment['HOME'] ?? path;
  if (path.startsWith('~/')) {
    final home = Platform.environment['HOME'];
    if (home != null) return '$home${path.substring(1)}';
  }
  return path;
}

/// Returns the first TCP port in `[start, end)` that nothing is currently
/// bound to on the loopback interface, skipping any in [avoid]. Falls back to
/// [start] if the whole range is taken (the caller still gets a sensible
/// default to show in the form).
Future<int> findFreePort({
  int start = 8000,
  int end = 8100,
  Set<int> avoid = const {},
}) async {
  for (var port = start; port < end; port++) {
    if (avoid.contains(port)) continue;
    try {
      // Bind 0.0.0.0 (not loopback): a server binding any-interface conflicts
      // with an existing dual-stack `[::]:port` listener that a loopback-only
      // probe would miss. Reflects what a launched server actually does.
      final socket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await socket.close();
      return port;
    } on SocketException {
      // In use — try the next one.
    }
  }
  return start;
}

/// One streamed chunk from a chat completion: a text [content] delta, the
/// server's running [completionTokens] count (llmd sends the latter each chunk
/// when `continuous_usage_stats` is on), and/or the choice's [finishReason]
/// (`stop`, `length`, …) once the reply ends.
typedef ChatToken = ({
  String? content,
  int? completionTokens,
  String? finishReason,
});

/// Streams a chat completion from `http://[host]:[port]/v1/chat/completions`
/// (OpenAI-compatible SSE) for the given [messages] (`[{role, content}, …]`).
/// Yields a [ChatToken] per `data:` event until `[DONE]`; cancel the
/// subscription to abort (closes the socket). Throws on a failed connection —
/// the caller marks that request failed.
///
/// A null [maxTokens] sends no cap — the server generates until EOS or its max
/// sequence length. A null [temperature] leaves sampling at the server default.
Stream<ChatToken> streamChat(
  String host,
  int port,
  List<Map<String, String>> messages, {
  int? maxTokens,
  double? temperature,
}) async* {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.post(host, port, '/v1/chat/completions');
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    request.add(utf8.encode(jsonEncode({
      'model': 'zml_model',
      'messages': messages,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (temperature != null) 'temperature': temperature,
      'stream': true,
      'stream_options': {
        'include_usage': true,
        'continuous_usage_stats': true,
      },
    })));
    final response = await request.close();
    final lines = response
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;
      Map<String, dynamic> json;
      try {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      String? content;
      String? finishReason;
      final choices = json['choices'];
      if (choices is List && choices.isNotEmpty && choices.first is Map) {
        final choice = choices.first as Map;
        final delta = choice['delta'];
        if (delta is Map) content = delta['content'] as String?;
        if (choice['finish_reason'] is String) {
          finishReason = choice['finish_reason'] as String;
        }
      }
      int? completionTokens;
      final usage = json['usage'];
      if (usage is Map && usage['completion_tokens'] is num) {
        completionTokens = (usage['completion_tokens'] as num).toInt();
      }
      yield (
        content: content,
        completionTokens: completionTokens,
        finishReason: finishReason,
      );
    }
  } finally {
    client.close(force: true);
  }
}

/// Fires one chat request with the `x-zml-profiler` header set, so llmd captures
/// a profile trace of it to `/tmp/xprof` (same mechanism as `chat.sh PROFILE=1`).
/// Drains the streamed response and returns when the request completes.
Future<void> runProfileRequest(
  String host,
  int port, {
  String prompt = 'Write a short paragraph about GPUs.',
  int maxTokens = 64,
}) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.post(host, port, '/v1/chat/completions');
    request.headers.contentType = ContentType.json;
    request.headers.set('x-zml-profiler', 'true');
    request.add(utf8.encode(jsonEncode({
      'model': 'zml_model',
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': maxTokens,
      'stream': true,
    })));
    final response = await request.close().timeout(const Duration(seconds: 180));
    await response.drain<void>();
  } finally {
    client.close(force: true);
  }
}

/// Result of probing an endpoint: HTTP status + body snippet + round-trip
/// latency, or an [error] string if the request never completed.
typedef EndpointProbe = ({int? status, String? body, int latencyMs, String? error});

/// Sends a GET to `http://[host]:[port][path]` and reports the outcome — for
/// the "Test endpoint" action. Reads (a capped slice of) the body so the caller
/// can show e.g. the `/v1/models` JSON.
Future<EndpointProbe> probeEndpoint(
  String host,
  int port, {
  String path = '/v1/models',
  Duration timeout = const Duration(seconds: 4),
}) async {
  final sw = Stopwatch()..start();
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.get(host, port, path).timeout(timeout);
    final response = await request.close().timeout(timeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(timeout);
    sw.stop();
    final snippet = body.length > 4000 ? body.substring(0, 4000) : body;
    return (
      status: response.statusCode,
      body: snippet,
      latencyMs: sw.elapsedMilliseconds,
      error: null,
    );
  } catch (e) {
    sw.stop();
    return (status: null, body: null, latencyMs: sw.elapsedMilliseconds, error: '$e');
  } finally {
    client.close(force: true);
  }
}

/// Whether something is accepting connections on `host:port` — a bare TCP
/// connect that's closed immediately, deliberately NOT an HTTP request:
/// servers log every request, so a `GET /health` heartbeat spams the job's
/// console. A plain connect never produces a request line to log. Semantics
/// match the old `/health` probe for llmd, which binds its listener only once
/// the model is loaded.
Future<bool> checkHealth(
  String host,
  int port, {
  Duration timeout = const Duration(milliseconds: 1200),
}) async {
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}
