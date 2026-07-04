import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed_data.dart';
import 'tables.dart';

part 'database.g.dart';

/// The app's single SQLite database (via drift).
///
/// On first creation it is seeded with a representative fleet + jobs so the
/// UI has something to render. Persistence is real; the *logic* that would
/// mutate this from live SSH sessions is deferred.
@DriftDatabase(tables: [Machines, LaunchConfigs, Jobs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'zml_lab',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDatabase(this);
    },
  );
}
