import 'package:freezed_annotation/freezed_annotation.dart';

part 'benchmark_chat.freezed.dart';

/// One message in a benchmark chat — either the user's prompt or the model's
/// (streamed) reply.
@freezed
abstract class ChatTurn with _$ChatTurn {
  const ChatTurn._();

  const factory ChatTurn({
    required bool fromUser,
    @Default('') String text,

    /// The model's thinking output (`reasoning_content`), shown above the reply.
    @Default('') String reasoning,
    @Default(false) bool streaming,
    @Default(0) int tokens,
    @Default(0.0) double tokensPerSecond,
    int? ttftMs,
    int? latencyMs,

    /// The server's `finish_reason` for the reply, once one arrived.
    String? finishReason,

    /// Why the reply failed, when it did — shown in place of the (empty) text.
    String? error,
  }) = _ChatTurn;

  /// Whether the reply was cut off by a token limit (see
  /// `BenchmarkRequest.truncated`).
  bool get truncated => finishReason == 'length';
}

/// A running conversation with a job's endpoint, seeded from the benchmark
/// request that was opened. Each user prompt fires a single request whose reply
/// streams in like a real chat.
@freezed
abstract class BenchmarkChat with _$BenchmarkChat {
  const BenchmarkChat._();

  const factory BenchmarkChat({
    @Default(<ChatTurn>[]) List<ChatTurn> turns,
  }) = _BenchmarkChat;

  /// True while the latest reply is still streaming in.
  bool get isStreaming => turns.isNotEmpty && turns.last.streaming;
}
