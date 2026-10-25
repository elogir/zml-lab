import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/database/database.dart';
import 'package:zml_lab/models/machine.dart';
import 'package:zml_lab/models/saved_benchmark.dart';
import 'package:zml_lab/repositories/machine_repository.dart';
import 'package:zml_lab/repositories/saved_benchmark_repository.dart';

SavedBenchmark _run(String id, String name) => SavedBenchmark(
  id: id,
  name: name,
  endpoint: 'local:8000',
  prompt: 'hi',
  batchSize: 4,
  aggregateTokensPerSecond: 100,
  completed: 4,
  medianTtftMs: 100,
  elapsedMs: 2000,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  test('importing an older database adds what this one lacks', () async {
    final dir = Directory.systemTemp.createTempSync('db_import_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final oldPath = '${dir.path}/zml_lab.sqlite';

    // An older install's file: two runs, a machine and a setting, from
    // before saved runs had notes and before endpoints existed.
    final old = AppDatabase(NativeDatabase(File(oldPath)));
    final oldRuns = DriftSavedBenchmarkRepository(old);
    await oldRuns.save(_run('b-1', 'old run'));
    await oldRuns.save(_run('b-2', 'old name'));
    await DriftMachineRepository(old).upsertMachine(
      const Machine(id: 'gb300', name: 'GB300-1', address: '10.0.0.5'),
    );
    await old.customStatement(
      "INSERT INTO settings (key, value) VALUES ('themeMode', 'light')",
    );
    await old.customStatement('ALTER TABLE saved_benchmarks DROP COLUMN notes');
    await old.customStatement('DROP TABLE api_endpoints');
    await old.close();

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final runs = DriftSavedBenchmarkRepository(db);
    await runs.save(_run('b-2', 'renamed here'));

    final gained = await db.importFrom(oldPath);
    expect(gained['saved_benchmarks'], 1);
    expect(gained['machines'], 1);
    expect(gained['settings'], 1);
    expect(gained.containsKey('api_endpoints'), isFalse);
    // What was here already stays as it is.
    expect(
      {for (final b in await runs.watchBenchmarks().first) b.id: b.name},
      {'b-1': 'old run', 'b-2': 'renamed here'},
    );
    expect(
      [for (final m in await DriftMachineRepository(db).allMachines()) m.name],
      ['GB300-1'],
    );

    // Importing the same file again adds nothing.
    expect((await db.importFrom(oldPath)).values.toSet(), {0});
  });
}
