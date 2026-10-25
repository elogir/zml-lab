import 'endpoint_repository.dart';

/// Web: no file system, so keys last for the session only.
ApiKeyStore createApiKeyStore() => _SessionApiKeyStore();

class _SessionApiKeyStore implements ApiKeyStore {
  final _keys = <String, String>{};

  @override
  Future<String?> read(String endpointId) async => _keys[endpointId];

  @override
  Future<void> write(String endpointId, String key) async =>
      _keys[endpointId] = key;

  @override
  Future<void> delete(String endpointId) async => _keys.remove(endpointId);
}
