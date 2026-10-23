import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';
import '../models/api_endpoint.dart';

part 'endpoint_repository.g.dart';

/// Saved endpoints (their API keys are in [ApiKeyStore], not here).
abstract interface class EndpointRepository {
  Stream<List<ApiEndpoint>> watchEndpoints();
  Future<void> save(ApiEndpoint endpoint);
  Future<void> delete(String id);
}

class DriftEndpointRepository implements EndpointRepository {
  DriftEndpointRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ApiEndpoint>> watchEndpoints() =>
      (_db.select(_db.apiEndpoints)
            ..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                ApiEndpoint(
                  id: r.id,
                  name: r.name,
                  baseUrl: r.baseUrl,
                  hasApiKey: r.hasApiKey,
                  createdAt: r.createdAt,
                ),
            ],
          );

  @override
  Future<void> save(ApiEndpoint e) => _db
      .into(_db.apiEndpoints)
      .insertOnConflictUpdate(
        ApiEndpointsCompanion.insert(
          id: e.id,
          name: e.name,
          baseUrl: e.baseUrl,
          hasApiKey: Value(e.hasApiKey),
          createdAt: e.createdAt,
        ),
      );

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.apiEndpoints)..where((t) => t.id.equals(id))).go();
}

@Riverpod(keepAlive: true)
EndpointRepository endpointRepository(Ref ref) =>
    DriftEndpointRepository(ref.watch(appDatabaseProvider));

/// API keys for saved endpoints, kept out of the database.
abstract interface class ApiKeyStore {
  Future<String?> read(String endpointId);
  Future<void> write(String endpointId, String key);
  Future<void> delete(String endpointId);
}

/// The macOS login Keychain. `usesDataProtectionKeychain: false` keeps it on
/// the classic keychain, which needs no keychain-access-group entitlement (so
/// unsigned dev builds work too).
class KeychainApiKeyStore implements ApiKeyStore {
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  static String _key(String endpointId) => 'zml-lab.endpoint.$endpointId';

  @override
  Future<String?> read(String endpointId) =>
      _storage.read(key: _key(endpointId));

  @override
  Future<void> write(String endpointId, String key) =>
      _storage.write(key: _key(endpointId), value: key);

  @override
  Future<void> delete(String endpointId) =>
      _storage.delete(key: _key(endpointId));
}

@Riverpod(keepAlive: true)
ApiKeyStore apiKeyStore(Ref ref) => KeychainApiKeyStore();
