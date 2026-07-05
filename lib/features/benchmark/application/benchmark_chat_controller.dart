import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/execution/native_io.dart';
import '../../../models/benchmark.dart';
import '../../../models/benchmark_chat.dart';
import 'benchmark_controller.dart';

part 'benchmark_chat_controller.g.dart';

/// Drives a real chat with a job's endpoint inside the benchmark focus popup.
/// Seeded (per job + request) from the clicked benchmark request; each [send]
/// appends the user's prompt and streams a single reply from
/// `/v1/chat/completions`, sending the whole conversation as context. Replies
/// use the benchmark run's max-tokens/temperature settings.
///
/// Keep-alive so the conversation (and an in-flight reply) survives closing
/// and reopening the popup; it resets itself when a new benchmark run
/// replaces the request it was seeded from.
@Riverpod(keepAlive: true)
class BenchmarkChatController extends _$BenchmarkChatController {
  StreamSubscription<ChatToken>? _sub;
  late String _jobId;
  late String _host;
  late int _port;

  /// While true, the seed reply (turn 1) live-mirrors its batch request — the
  /// popup can be opened mid-run and the reply keeps streaming in. Cleared
  /// once the request settles or the user replays the prompt.
  bool _mirrorBatch = false;

  @override
  BenchmarkChat build(String jobId, int index, String host, int port) {
    _jobId = jobId;
    _host = host;
    _port = port;
    ref.onDispose(() => _sub?.cancel());
    // Seed the first turn from the request that was opened: its prompt and the
    // reply it already produced in the batch.
    final run = ref.read(benchmarkControllerProvider(jobId));
    final request = run.requests.firstWhere(
      (r) => r.index == index,
      orElse: () => BenchmarkRequest(index: index),
    );
    // Opened mid-run: keep mirroring the still-streaming request into the
    // seed reply until it finishes. Opened after, the seed is a snapshot.
    _mirrorBatch = request.status == BenchmarkRequestStatus.streaming;
    final seedToken = run.runToken;
    ref.listen(benchmarkControllerProvider(jobId), (_, next) {
      // A new batch replaced the request this chat was seeded from — the
      // conversation is stale, so start over from the fresh request.
      if (next.runToken != seedToken) {
        ref.invalidateSelf();
        return;
      }
      if (_mirrorBatch) {
        _mirrorSeed(
          next.requests.firstWhere(
            (r) => r.index == index,
            orElse: () => BenchmarkRequest(index: index),
          ),
        );
      }
    });
    return BenchmarkChat(
      turns: [
        ChatTurn(fromUser: true, text: run.prompt),
        _seedTurn(request),
      ],
    );
  }

  ChatTurn _seedTurn(BenchmarkRequest r) => ChatTurn(
    fromUser: false,
    text: r.text,
    streaming: r.status == BenchmarkRequestStatus.streaming,
    tokens: r.tokens,
    tokensPerSecond: r.tokensPerSecond,
    ttftMs: r.ttftMs,
    latencyMs: r.latencyMs,
    finishReason: r.finishReason,
  );

  /// Folds the live batch request into the seed reply while it's streaming.
  void _mirrorSeed(BenchmarkRequest r) {
    if (!_mirrorBatch || state.turns.length < 2) return;
    _setTurn(1, _seedTurn(r));
    if (r.status.isTerminal) _mirrorBatch = false; // settled — snapshot now
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
    // The user is driving the conversation now — a replay replaces turn 1, so
    // the batch request must stop writing into it.
    _mirrorBatch = false;
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
    String? finishReason;

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
          finishReason: finishReason,
        ),
      );
    }

    // Chat replies follow the run's settings, read fresh per send.
    final run = ref.read(benchmarkControllerProvider(_jobId));
    _sub =
        streamChat(
          _host,
          _port,
          messages,
          maxTokens: run.maxTokens,
          temperature: run.temperature,
        ).listen(
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
            if (tok.finishReason != null) finishReason = tok.finishReason;
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
