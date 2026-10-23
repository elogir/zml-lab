// Web stub: no dart:io, so chat streaming and health checks aren't available.
// Benchmarking and machine probes are native-only.

typedef ChatToken = ({
  String? content,
  String? reasoning,
  int? completionTokens,
  String? finishReason,
});

Stream<ChatToken> streamChat(
  String host,
  int port,
  List<Map<String, String>> messages, {
  int? maxTokens,
  double? temperature,
  String model = '',
}) async* {
  // No dart:io on web — benchmarking is native-only.
}

Future<bool> checkHealth(
  String host,
  int port, {
  Duration timeout = const Duration(milliseconds: 1200),
}) async => false;
