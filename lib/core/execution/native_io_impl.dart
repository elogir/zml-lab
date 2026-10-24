import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'chat_endpoint.dart';

export 'chat_endpoint.dart';

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

/// Streams a chat completion from [endpoint]'s `/chat/completions`
/// (OpenAI-compatible SSE, http or https, with its bearer key if any) for the given [messages] (`[{role, content}, …]`).
/// Yields a [ChatToken] per `data:` event until `[DONE]`; cancel the
/// subscription to abort (closes the socket). Throws on a failed connection —
/// the caller marks that request failed.
///
/// A null [maxTokens] sends no cap — the server generates until EOS or its max
/// sequence length. A null [temperature] leaves sampling at the server default.
/// An empty [model] sends `zml_model` (llmd ignores the name; vLLM rejects a
/// request whose model it doesn't serve, so it must be set for those).
Stream<ChatToken> streamChat(
  ChatEndpoint endpoint,
  List<Map<String, String>> messages, {
  int? maxTokens,
  double? temperature,
  String model = '',
}) async* {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.postUrl(endpoint.chatCompletions);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    final key = endpoint.apiKey;
    if (key != null && key.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
    }
    request.add(
      utf8.encode(
        jsonEncode({
          'model': model.isEmpty ? 'zml_model' : model,
          'messages': messages,
          'max_tokens': ?maxTokens,
          'temperature': ?temperature,
          'stream': true,
          'stream_options': {
            'include_usage': true,
            // Running token counts per chunk (vLLM, llmd). Hosted APIs like
            // OpenAI reject it as an unknown argument.
            if (endpoint.selfHosted) 'continuous_usage_stats': true,
          },
        }),
      ),
    );
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
      if (err is Map && err['message'] is String) {
        return err['message'] as String;
      }
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

/// What one request of a [streamChatBatch] did since the previous update.
/// Times are wall-clock microseconds taken where the bytes arrived, so ttft
/// and latency are exact however the updates are batched.
typedef ChatBatchDelta = ({
  int index,
  int? startUs,
  int? firstTokenUs,
  String content,
  String reasoning,
  int chunks,
  int? completionTokens,
  String? finishReason,
  bool done,
  int? endUs,
  String? error,
});

/// Fires [count] identical streaming chat requests (indices 1..count) from a
/// background isolate and emits their progress merged into one list per
/// [interval]. Receiving and parsing hundreds of SSE streams is tens of
/// thousands of events a second; on the UI isolate that alone starved
/// rendering. Cancelling the subscription kills the isolate (closing every
/// socket). The stream closes once every request has finished.
Stream<List<ChatBatchDelta>> streamChatBatch(
  ChatEndpoint endpoint,
  List<Map<String, String>> messages, {
  required int count,
  int? maxTokens,
  double? temperature,
  String model = '',
  Duration interval = const Duration(milliseconds: 50),
}) {
  final fromWorker = ReceivePort();
  Isolate? worker;
  var cancelled = false;
  late final StreamController<List<ChatBatchDelta>> controller;
  controller = StreamController(
    onListen: () async {
      fromWorker.listen((msg) {
        if (msg == null) {
          fromWorker.close();
          controller.close();
        } else {
          controller.add((msg as List).cast<ChatBatchDelta>());
        }
      });
      try {
        worker = await Isolate.spawn(_chatBatchWorker, (
          fromWorker.sendPort,
          endpoint,
          messages,
          count,
          maxTokens,
          temperature,
          model,
          interval.inMicroseconds,
        ), debugName: 'benchmark batch');
      } catch (e) {
        controller.addError(e);
        fromWorker.close();
        await controller.close();
        return;
      }
      if (cancelled) worker?.kill(priority: Isolate.immediate);
    },
    onCancel: () {
      cancelled = true;
      worker?.kill(priority: Isolate.immediate);
      fromWorker.close();
    },
  );
  return controller.stream;
}

/// Mutable per-request accumulator inside the batch worker.
class _BatchProgress {
  _BatchProgress(this.index);
  final int index;
  int? startUs;
  int? firstTokenUs;
  bool sentFirst = false;
  final content = StringBuffer();
  final reasoning = StringBuffer();
  int chunks = 0;
  int? completionTokens;
  String? finishReason;
  bool done = false;
  int? endUs;
  String? error;
  bool dirty = false;

  ChatBatchDelta take() {
    final delta = (
      index: index,
      startUs: startUs,
      firstTokenUs: sentFirst ? null : firstTokenUs,
      content: content.toString(),
      reasoning: reasoning.toString(),
      chunks: chunks,
      completionTokens: completionTokens,
      finishReason: finishReason,
      done: done,
      endUs: endUs,
      error: error,
    );
    if (firstTokenUs != null) sentFirst = true;
    startUs = null;
    content.clear();
    reasoning.clear();
    chunks = 0;
    dirty = false;
    return delta;
  }
}

Future<void> _chatBatchWorker(
  (
    SendPort,
    ChatEndpoint,
    List<Map<String, String>>,
    int,
    int?,
    double?,
    String,
    int,
  )
  args,
) async {
  final (out, endpoint, messages, count, maxTokens, temperature, model, us) =
      args;
  final progress = [for (var i = 1; i <= count; i++) _BatchProgress(i)];
  var remaining = count;
  int now() => DateTime.now().microsecondsSinceEpoch;

  void send() {
    final deltas = [
      for (final p in progress)
        if (p.dirty) p.take(),
    ];
    if (deltas.isNotEmpty) out.send(deltas);
  }

  final ticker = Timer.periodic(Duration(microseconds: us), (_) => send());

  void finish(_BatchProgress p, {String? error}) {
    if (p.done) return;
    p
      ..done = true
      ..endUs = now()
      ..error = error
      ..dirty = true;
    remaining--;
    // The first completion freezes the aggregate; show it without waiting.
    if (remaining == count - 1) send();
    if (remaining == 0) {
      ticker.cancel();
      send();
      Isolate.exit(out, null);
    }
  }

  for (final p in progress) {
    p
      ..startUs = now()
      ..dirty = true;
    streamChat(
      endpoint,
      messages,
      maxTokens: maxTokens,
      temperature: temperature,
      model: model,
    ).listen(
      (tok) {
        final content = tok.content;
        final reasoning = tok.reasoning;
        final hasContent = content != null && content.isNotEmpty;
        final hasReasoning = reasoning != null && reasoning.isNotEmpty;
        if (hasContent || hasReasoning) p.firstTokenUs ??= now();
        if (hasReasoning) {
          p.reasoning.write(reasoning);
          p.chunks++;
        }
        if (hasContent) {
          p.content.write(content);
          p.chunks++;
        }
        if (tok.completionTokens != null && tok.completionTokens! > 0) {
          p.completionTokens = tok.completionTokens;
        }
        if (tok.finishReason != null) p.finishReason = tok.finishReason;
        p.dirty = true;
      },
      onError: (Object e) {
        final s = e.toString();
        finish(
          p,
          error: s.startsWith('Exception: ')
              ? s.substring('Exception: '.length)
              : s,
        );
      },
      onDone: () => finish(p),
      cancelOnError: true,
    );
  }
}

/// Whether [host] answers a ping (one echo request, given [timeout] to
/// reply) — the machines' reachability dot. Needs nothing from the host but
/// ICMP: no ssh, no open port. A host whose firewall drops pings reads as
/// unreachable.
Future<bool> pingHost(
  String host, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final h = host.trim();
  if (h.isEmpty) return false;
  try {
    final ping = await Process.start(h.contains(':') ? 'ping6' : 'ping', [
      '-c',
      '1',
      '-q',
      h,
    ]);
    unawaited(ping.stdout.drain<void>());
    unawaited(ping.stderr.drain<void>());
    final code = await ping.exitCode.timeout(
      timeout,
      onTimeout: () {
        ping.kill();
        return -1;
      },
    );
    return code == 0;
  } catch (_) {
    return false;
  }
}
