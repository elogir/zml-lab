import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/execution/native_io.dart';
import '../../../models/benchmark.dart';
import '../../../models/benchmark_chat.dart';
import 'benchmark_controller.dart';

part 'benchmark_chat_controller.g.dart';

/// Strips the `Exception: ` wrapper off streamChat's already-clean message.
String _cleanError(Object e) {
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
}

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

  /// Releases the batch's live-text watch on the mirrored request (a big
  /// batch only keeps watched requests' text current — see
  /// [BenchmarkController.watchText]). Null when not watching.
  void Function()? _unwatch;

  void _stopMirroring() {
    _mirrorBatch = false;
    _unwatch?.call();
    _unwatch = null;
  }

  /// Bumped per reply, so a frame-deferred write from a replaced (replayed)
  /// reply can't land in the new one.
  int _generation = 0;

  /// Identity, not the default deep `==` over every turn's text.
  @override
  bool updateShouldNotify(BenchmarkChat previous, BenchmarkChat next) =>
      !identical(previous, next);

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
    if (_mirrorBatch) {
      final batch = ref.read(benchmarkControllerProvider(jobId).notifier)
        ..watchText(index);
      _unwatch = () => batch.unwatchText(index);
    }
    ref.onDispose(_stopMirroring);
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
    reasoning: r.reasoning,
    streaming: r.status == BenchmarkRequestStatus.streaming,
    tokens: r.tokens,
    tokensPerSecond: r.tokensPerSecond,
    ttftMs: r.ttftMs,
    latencyMs: r.latencyMs,
    finishReason: r.finishReason,
    error: r.status == BenchmarkRequestStatus.failed ? r.error : null,
  );

  /// Folds the live batch request into the seed reply while it's streaming.
  void _mirrorSeed(BenchmarkRequest r) {
    if (!_mirrorBatch || state.turns.length < 2) return;
    _setTurn(1, _seedTurn(r));
    if (r.status.isTerminal) _stopMirroring(); // settled — snapshot now
  }

  /// Fire a single request: append the user's prompt, then stream a reply.
  void send(String prompt) {
    if (prompt.trim().isEmpty || state.isStreaming) return;
    state = state.copyWith(
      turns: [
        ...state.turns,
        ChatTurn(fromUser: true, text: prompt),
      ],
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
    _stopMirroring();
    _sub?.cancel();
    _generation++;
    final messages = _messages();
    final start = DateTime.now();
    final replyIndex = state.turns.length;
    state = state.copyWith(
      turns: [...state.turns, const ChatTurn(fromUser: false, streaming: true)],
    );

    DateTime? firstTokenAt;
    final buffer = StringBuffer();
    final reasoning = StringBuffer();
    var chunkTokens = 0;
    var usageTokens = 0;
    String? finishReason;

    // Tokens arrive far faster than frames; publishing each one re-copied the
    // whole reply and re-rendered it per token, so long replies crawled.
    // Streaming updates are folded into one per frame; the final one is not.
    var frameScheduled = false;
    var generation = _generation;
    String text = '', thinking = '';

    void write({required bool streaming, String? error}) {
      if (generation != _generation) return; // a newer reply took over
      if (buffer.length != text.length) text = buffer.toString();
      if (reasoning.length != thinking.length) thinking = reasoning.toString();
      final tokens = usageTokens > 0 ? usageTokens : chunkTokens;
      final now = DateTime.now();
      final decodeMs = firstTokenAt == null
          ? 0
          : now.difference(firstTokenAt!).inMilliseconds;
      // Rate of tokens after the first (see the batch controller) — avoids the
      // early spike from one token over a near-zero window.
      final tps = (tokens > 1 && decodeMs > 0 && (!streaming || decodeMs >= 50))
          ? (tokens - 1) / (decodeMs / 1000.0)
          : 0.0;
      _setTurn(
        replyIndex,
        ChatTurn(
          fromUser: false,
          text: text,
          reasoning: thinking,
          streaming: streaming,
          tokens: tokens,
          tokensPerSecond: tps,
          ttftMs: firstTokenAt?.difference(start).inMilliseconds,
          latencyMs: streaming ? null : now.difference(start).inMilliseconds,
          finishReason: finishReason,
          error: error,
        ),
      );
    }

    // Re-rendering the streaming reply costs more the longer it gets, so past
    // a few pages it updates ~10×/s instead of every frame.
    void scheduleWrite() {
      if (frameScheduled) return;
      frameScheduled = true;
      void onFrame() => SchedulerBinding.instance.scheduleFrameCallback((_) {
        frameScheduled = false;
        write(streaming: true);
      });
      if (buffer.length > 8000) {
        Timer(const Duration(milliseconds: 100), onFrame);
      } else {
        onFrame();
      }
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
          model: run.model,
        ).listen(
          (tok) {
            final content = tok.content;
            final reason = tok.reasoning;
            final hasContent = content != null && content.isNotEmpty;
            final hasReasoning = reason != null && reason.isNotEmpty;
            // Clock starts at the first real token (see the batch controller),
            // so the ttft isn't folded into the tok/s window.
            if (hasContent || hasReasoning) firstTokenAt ??= DateTime.now();
            if (hasReasoning) {
              reasoning.write(reason);
              chunkTokens += 1;
            }
            if (hasContent) {
              buffer.write(content);
              chunkTokens += 1;
            }
            if (tok.completionTokens != null && tok.completionTokens! > 0) {
              usageTokens = tok.completionTokens!;
            }
            if (tok.finishReason != null) finishReason = tok.finishReason;
            scheduleWrite();
          },
          // A frame write still pending after these sees the reply settled
          // and is dropped (generation bump), so it can't flip it back.
          onError: (Object e) {
            write(streaming: false, error: _cleanError(e));
            generation = -1;
          },
          onDone: () {
            write(streaming: false);
            generation = -1;
          },
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
