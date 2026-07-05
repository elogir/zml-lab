import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';

part 'settings_repository.g.dart';

/// Persists app settings as string key/value rows. Absent key = default.
abstract interface class SettingsRepository {
  Future<Map<String, String>> all();
  Future<void> put(String key, String value);
  Future<void> remove(String key);
  Future<void> clear();
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Map<String, String>> all() async {
    final rows = await _db.select(_db.settings).get();
    return {for (final r in rows) r.key: r.value};
  }

  @override
  Future<void> put(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  @override
  Future<void> remove(String key) =>
      (_db.delete(_db.settings)..where((t) => t.key.equals(key))).go();

  @override
  Future<void> clear() => _db.delete(_db.settings).go();
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    DriftSettingsRepository(ref.watch(appDatabaseProvider));
