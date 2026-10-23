/// Where chat requests go: an OpenAI-compatible API root (`…/v1`) and an
/// optional bearer key. A machine or a typed host is `http://host:port/v1`
/// with no key; a saved endpoint can be any http(s) URL (OpenAI, a remote
/// vLLM, …).
class ChatEndpoint {
  const ChatEndpoint(this.baseUrl, {this.apiKey, this.selfHosted = false});

  /// A server on a machine or a typed host, reached directly.
  factory ChatEndpoint.hostPort(String host, int port) =>
      ChatEndpoint(Uri.http('$host:$port', '/v1'), selfHosted: true);

  /// The API root, e.g. `https://api.openai.com/v1`.
  final Uri baseUrl;

  /// Sent as `Authorization: Bearer …` when set.
  final String? apiKey;

  /// A server we launched (llmd, vLLM): it gets the extended usage stream
  /// option, which hosted APIs like OpenAI reject as an unknown argument.
  final bool selfHosted;

  Uri get chatCompletions => _under('chat/completions');
  Uri get models => _under('models');

  Uri _under(String path) {
    final base = baseUrl.path.endsWith('/')
        ? baseUrl.path.substring(0, baseUrl.path.length - 1)
        : baseUrl.path;
    return baseUrl.replace(path: '$base/$path');
  }

  /// Host and port, for tools that only take those (the perf load generator).
  String get host => baseUrl.host;
  int get port => baseUrl.hasPort
      ? baseUrl.port
      : (baseUrl.scheme == 'https' ? 443 : 80);

  /// Parses what a user typed as an API root; null when it isn't one. A bare
  /// `host:port` is taken as `http://host:port/v1`.
  static Uri? parseBaseUrl(String text) {
    var t = text.trim();
    if (t.isEmpty) return null;
    if (!t.contains('://')) t = 'http://$t';
    final uri = Uri.tryParse(t);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    // No path at all: OpenAI-compatible servers serve under /v1.
    return uri.path.isEmpty || uri.path == '/' ? uri.replace(path: '/v1') : uri;
  }

  @override
  bool operator ==(Object other) =>
      other is ChatEndpoint &&
      other.baseUrl == baseUrl &&
      other.apiKey == apiKey &&
      other.selfHosted == selfHosted;

  @override
  int get hashCode => Object.hash(baseUrl, apiKey, selfHosted);

  @override
  String toString() => 'ChatEndpoint($baseUrl)';
}
