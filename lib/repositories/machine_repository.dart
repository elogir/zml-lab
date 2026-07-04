import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';
import '../models/machine.dart';
import 'mappers.dart';

part 'machine_repository.g.dart';

/// Reads/observes the fleet of remote machines. Write paths are stubbed for
/// this UI pass.
abstract interface class MachineRepository {
  Stream<List<Machine>> watchMachines();
  Stream<Machine?> watchMachine(String id);
  Future<List<Machine>> allMachines();
  Future<void> deleteMachine(String id);
  Future<Machine?> machineById(String id);
  Future<void> upsertMachine(Machine machine);
}

class DriftMachineRepository implements MachineRepository {
  DriftMachineRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Machine>> watchMachines() => (_db.select(
    _db.machines,
  )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch().map(
    (rows) => rows.map((r) => r.toModel()).toList(),
  );

  @override
  Stream<Machine?> watchMachine(String id) =>
      (_db.select(_db.machines)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((r) => r?.toModel());

  @override
  Future<List<Machine>> allMachines() async =>
      (await _db.select(_db.machines).get()).map((r) => r.toModel()).toList();

  @override
  Future<void> deleteMachine(String id) =>
      (_db.delete(_db.machines)..where((t) => t.id.equals(id))).go();

  @override
  Future<Machine?> machineById(String id) async {
    final row = await (_db.select(
      _db.machines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  @override
  Future<void> upsertMachine(Machine m) =>
      _db.into(_db.machines).insertOnConflictUpdate(
        MachinesCompanion.insert(
          id: m.id,
          name: m.name,
          address: m.address,
          sshPort: Value(m.sshPort),
          user: Value(m.user),
          sshKey: Value(m.sshKey),
          vendor: Value(m.vendor?.name),
          gpus: Value(m.gpus),
          memory: Value(m.memory),
          online: Value(m.online),
        ),
      );
}

@Riverpod(keepAlive: true)
MachineRepository machineRepository(Ref ref) =>
    DriftMachineRepository(ref.watch(appDatabaseProvider));
