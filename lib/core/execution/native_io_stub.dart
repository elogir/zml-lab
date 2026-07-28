// Web stub: no dart:io, so port scanning and health checks aren't available.
// Execution is native-only; on web the form just shows a default port and no
// job is ever launched.

Future<void> killPortListeners(int port, {bool force = false}) async {}

Future<void> killRemotePortListeners({
  required String target,
  required int port,
  int sshPort = 22,
  String? identityFile,
  bool force = false,
  Duration timeout = const Duration(seconds: 8),
}) async {}

String expandUser(String path) => path;

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

Future<void> runProfileRequest(
  String host,
  int port, {
  String prompt = '',
  int maxTokens = 64,
}) async {}

typedef EndpointProbe = ({int? status, String? body, int latencyMs, String? error});

Future<EndpointProbe> probeEndpoint(
  String host,
  int port, {
  String path = '/v1/models',
  Duration timeout = const Duration(seconds: 4),
}) async => (
  status: null,
  body: null,
  latencyMs: 0,
  error: 'Endpoint testing is native-only',
);

Future<int> findFreePort({
  int start = 8000,
  int end = 8100,
  Set<int> avoid = const {},
}) async => start;

Future<bool> checkHealth(
  String host,
  int port, {
  Duration timeout = const Duration(milliseconds: 1200),
}) async => false;
