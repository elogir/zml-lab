// Web stub: no dart:io, so chat streaming and health checks aren't available.
// Benchmarking and machine probes are native-only.

import 'chat_endpoint.dart';

export 'chat_endpoint.dart';

typedef ChatToken = ({
  String? content,
  String? reasoning,
  int? completionTokens,
  String? finishReason,
});

Stream<ChatToken> streamChat(
  ChatEndpoint endpoint,
  List<Map<String, String>> messages, {
  int? maxTokens,
  double? temperature,
  String model = '',
}) async* {
  // No dart:io on web — benchmarking is native-only.
}

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

/// Every request ends at once with nothing streamed (no networking on web).
Stream<List<ChatBatchDelta>> streamChatBatch(
  ChatEndpoint endpoint,
  List<Map<String, String>> messages, {
  required int count,
  int? maxTokens,
  double? temperature,
  String model = '',
  Duration interval = const Duration(milliseconds: 50),
}) {
  final now = DateTime.now().microsecondsSinceEpoch;
  return Stream.value([
    for (var i = 1; i <= count; i++)
      (
        index: i,
        startUs: now,
        firstTokenUs: null,
        content: '',
        reasoning: '',
        chunks: 0,
        completionTokens: null,
        finishReason: null,
        done: true,
        endUs: now,
        error: null,
      ),
  ]);
}

Future<bool> checkHealth(
  String host,
  int port, {
  Duration timeout = const Duration(milliseconds: 1200),
}) async => false;
