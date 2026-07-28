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

/// One streamed chunk from a chat completion: a text [content] delta, a
/// [reasoning] (thinking) delta for reasoning models — llmd routes `<think>`
/// output to `delta.reasoning_content`, separate from content — the server's
/// running [completionTokens] count (sent each chunk when
/// `continuous_usage_stats` is on, and already inclusive of reasoning tokens),
/// and/or the choice's [finishReason] (`stop`, `length`, …) once it ends.
typedef ChatToken = ({
  String? content,
  String? reasoning,
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
/// An empty [model] sends `zml_model` (llmd ignores the name; vLLM rejects a
/// request whose model it doesn't serve, so it must be set for those).
Stream<ChatToken> streamChat(
  String host,
  int port,
  List<Map<String, String>> messages, {
  int? maxTokens,
  double? temperature,
  String model = '',
}) async* {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.post(host, port, '/v1/chat/completions');
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    request.add(utf8.encode(jsonEncode({
      'model': model.isEmpty ? 'zml_model' : model,
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
    if (response.statusCode >= 400) {
      // The body isn't SSE — it's the server's error (usually an OpenAI-shape
      // JSON). Surface it so the request card can show why it failed instead
      // of a bare "failed".
      final body = await response.transform(utf8.decoder).join();
      throw Exception('HTTP ${response.statusCode}: ${_errorSnippet(body)}');
    }
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
      String? reasoning;
      String? finishReason;
      final choices = json['choices'];
      if (choices is List && choices.isNotEmpty && choices.first is Map) {
        final choice = choices.first as Map;
        final delta = choice['delta'];
        if (delta is Map) {
          content = delta['content'] as String?;
          reasoning = delta['reasoning_content'] as String?;
        }
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
        reasoning: reasoning,
        completionTokens: completionTokens,
        finishReason: finishReason,
      );
    }
  } on Object catch (e) {
    // Rethrow with a clean, human message (the raw SocketException/HttpException
    // toString is noisy). The benchmark controller shows this on the card.
    throw Exception(describeIoError(e));
  } finally {
    client.close(force: true);
  }
}

/// A short, human-readable message for a network error thrown while talking to
/// a server — used on the benchmark request cards. Strips the noisy wrapper
/// text off the common dart:io exceptions.
String describeIoError(Object e) {
  if (e is SocketException) {
    final os = e.osError?.message.trim();
    if (os != null && os.isNotEmpty) return os; // e.g. "Connection refused"
    return e.message.isEmpty ? 'connection failed' : e.message;
  }
  if (e is HttpException) return e.message;
  if (e is TimeoutException) return 'timed out';
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
}

/// How much of an unstructured error body to keep. Generous on purpose: the
/// expanded request card shows this in full (it scrolls), and a server error
/// is only useful if it isn't cut off mid-sentence. Still bounded so a stray
/// HTML page can't be carried around whole.
const _maxErrorBodyChars = 4000;

/// Pulls a message out of an error response body — OpenAI's `{"error":{...}}`
/// shape when present, else a trimmed snippet of the raw body.
String _errorSnippet(String body) {
  try {
    final json = jsonDecode(body);
    if (json is Map) {
      final err = json['error'];
      if (err is Map && err['message'] is String) return err['message'] as String;
      if (err is String && err.isNotEmpty) return err;
      if (json['message'] is String) return json['message'] as String;
    }
  } catch (_) {}
  final t = body.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return 'no response body';
  return t.length > _maxErrorBodyChars
      ? '${t.substring(0, _maxErrorBodyChars)}…'
      : t;
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
