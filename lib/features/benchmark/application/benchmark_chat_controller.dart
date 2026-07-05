import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/execution/native_io.dart';
import '../../../models/benchmark.dart';
import '../../../models/benchmark_chat.dart';
import 'benchmark_controller.dart';

part 'benchmark_chat_controller.g.dart';

/// Tokens a single chat reply asks for — longer than a batch request since this
/// is an interactive conversation, not a throughput probe.
const _chatMaxTokens = 512;

/// Drives a real chat with a job's endpoint inside the benchmark focus popup.
/// Seeded (per job + request) from the clicked benchmark request; each [send]
/// appends the user's prompt and streams a single reply from
/// `/v1/chat/completions`, sending the whole conversation as context.
@riverpod
class BenchmarkChatController extends _$BenchmarkChatController {
  StreamSubscription<ChatToken>? _sub;
  late String _host;
  late int _port;

  @override
  BenchmarkChat build(String jobId, int index, String host, int port) {
    _host = host;
    _port = port;
    ref.onDispose(() => _sub?.cancel());
    // Seed the first turn from the request that was opened: its prompt and the
    // reply it already produced in the batch. Read (not watch) — the chat is a
    // snapshot the user drives from here, not a live mirror of the batch.
    final run = ref.read(benchmarkControllerProvider(jobId));
    final request = run.requests.firstWhere(
      (r) => r.index == index,
      orElse: () => BenchmarkRequest(index: index),
    );
    return BenchmarkChat(
      turns: [
        ChatTurn(fromUser: true, text: run.prompt),
        ChatTurn(
          fromUser: false,
          text: request.text,
          tokens: request.tokens,
          tokensPerSecond: request.tokensPerSecond,
          ttftMs: request.ttftMs,
          latencyMs: request.latencyMs,
        ),
      ],
    );
  }

  /// Fire a single request: append the user's prompt, then stream a reply.
  void send(String prompt) {
    if (prompt.trim().isEmpty || state.isStreaming) return;
    state = state.copyWith(
      turns: [...state.turns, ChatTurn(fromUser: true, text: prompt)],
    );
    _startReply();
  }

  /// Re-run a user message: drop everything after it and stream a fresh reply,
  /// as if the prompt had just been sent again.
  void replay(int turnIndex) {
    if (turnIndex < 0 || turnIndex >= state.turns.length) return;
    if (!state.turns[turnIndex].fromUser) return;
    _sub?.cancel();
    state = state.copyWith(turns: state.turns.sublist(0, turnIndex + 1));
    _startReply();
  }

  /// The conversation so far as OpenAI chat messages (skipping any empty seed
  /// reply so we don't send a blank assistant turn).
  List<Map<String, String>> _messages() => [
    for (final t in state.turns)
      if (t.text.trim().isNotEmpty)
        {'role': t.fromUser ? 'user' : 'assistant', 'content': t.text},
  ];

  /// Append an empty reply turn and stream the real answer into it.
  void _startReply() {
    _sub?.cancel();
    final messages = _messages();
    final start = DateTime.now();
    final replyIndex = state.turns.length;
    state = state.copyWith(
      turns: [...state.turns, const ChatTurn(fromUser: false, streaming: true)],
    );

    DateTime? firstTokenAt;
    final buffer = StringBuffer();
    var chunkTokens = 0;
    var usageTokens = 0;

    void write({required bool streaming, bool failed = false}) {
      final tokens = usageTokens > 0 ? usageTokens : chunkTokens;
      final now = DateTime.now();
      final decodeMs = firstTokenAt == null
          ? 0
          : now.difference(firstTokenAt!).inMilliseconds;
      final tps = decodeMs > 0 ? tokens / (decodeMs / 1000.0) : 0.0;
      final text = buffer.toString();
      _setTurn(
        replyIndex,
        ChatTurn(
          fromUser: false,
          text: text.isEmpty && failed ? '(request failed)' : text,
          streaming: streaming,
          tokens: tokens,
          tokensPerSecond: tps,
          ttftMs: firstTokenAt?.difference(start).inMilliseconds,
          latencyMs: streaming ? null : now.difference(start).inMilliseconds,
        ),
      );
    }

    _sub = streamChat(_host, _port, messages, maxTokens: _chatMaxTokens).listen(
      (tok) {
        firstTokenAt ??= DateTime.now();
        final content = tok.content;
        if (content != null && content.isNotEmpty) {
          buffer.write(content);
          chunkTokens += 1;
        }
        if (tok.completionTokens != null && tok.completionTokens! > 0) {
          usageTokens = tok.completionTokens!;
        }
        write(streaming: true);
      },
      onError: (_) => write(streaming: false, failed: true),
      onDone: () => write(streaming: false),
      cancelOnError: true,
    );
  }

  void _setTurn(int i, ChatTurn turn) {
    if (i < 0 || i >= state.turns.length) return;
    final turns = [...state.turns];
    turns[i] = turn;
    state = state.copyWith(turns: turns);
  }
}
