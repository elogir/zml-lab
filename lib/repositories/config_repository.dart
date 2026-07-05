import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';
import '../models/launch_config.dart';
import 'mappers.dart';

part 'config_repository.g.dart';

/// Reads/observes saved launch configs, and persists them.
abstract interface class ConfigRepository {
  Stream<List<LaunchConfig>> watchConfigs();
  Future<LaunchConfig?> configById(String id);
  Future<void> upsertConfig(LaunchConfig config);
  Future<void> deleteConfig(String id);
}

class DriftConfigRepository implements ConfigRepository {
  DriftConfigRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<LaunchConfig>> watchConfigs() => (_db.select(
    _db.launchConfigs,
  )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch().map(
    (rows) => rows.map((r) => r.toModel()).toList(),
  );

  @override
  Future<LaunchConfig?> configById(String id) async {
    final row = await (_db.select(
      _db.launchConfigs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  @override
  Future<void> upsertConfig(LaunchConfig c) =>
      _db.into(_db.launchConfigs).insertOnConflictUpdate(
        LaunchConfigsCompanion.insert(
          id: c.id,
          name: c.name,
          description: Value(c.description),
          machineId: c.machineId,
          program: c.program,
          command: c.command,
          workingDir: Value(c.workingDir),
          port: c.port,
          envJson: Value(encodeEnv(c.env)),
        ),
      );

  @override
  Future<void> deleteConfig(String id) =>
      (_db.delete(_db.launchConfigs)..where((t) => t.id.equals(id))).go();
}

@Riverpod(keepAlive: true)
ConfigRepository configRepository(Ref ref) =>
    DriftConfigRepository(ref.watch(appDatabaseProvider));
