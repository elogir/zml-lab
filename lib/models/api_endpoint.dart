/// A saved OpenAI-compatible endpoint the Benchmark tab can target: a hosted
/// API (OpenAI, …) or a server reached by URL. Its API key, if any, lives in
/// the Keychain under [id] — [hasApiKey] only records that one is stored.
class ApiEndpoint {
  const ApiEndpoint({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.createdAt,
    this.hasApiKey = false,
  });

  final String id;
  final String name;

  /// The API root requests go under, e.g. `https://api.openai.com/v1`.
  final String baseUrl;
  final bool hasApiKey;
  final DateTime createdAt;

  /// The host, for compact display next to the name.
  String get host => Uri.tryParse(baseUrl)?.host ?? baseUrl;

  ApiEndpoint copyWith({String? name, String? baseUrl, bool? hasApiKey}) =>
      ApiEndpoint(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        hasApiKey: hasApiKey ?? this.hasApiKey,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      other is ApiEndpoint &&
      other.id == id &&
      other.name == name &&
      other.baseUrl == baseUrl &&
      other.hasApiKey == hasApiKey &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, baseUrl, hasApiKey, createdAt);
}
