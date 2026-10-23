import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
      'max_tokens': ?maxTokens,
      'temperature': ?temperature,
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
