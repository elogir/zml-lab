import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// The app's single SQLite database (via drift). Starts empty — the local
/// machine is added at startup (`ensureLocalMachine`); machines, configs and
/// jobs are all created by the user.
@DriftDatabase(
  tables: [
    Machines,
    LaunchConfigs,
    Jobs,
    BrowserHistoryEntries,
    SavedBenchmarks,
    Settings,
  ],
)
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
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(browserHistoryEntries);
      if (from < 3) await m.createTable(savedBenchmarks);
      if (from < 4) {
        // Dropped the derived `program` badge — it's redundant with name/desc.
        await m.database.customStatement('ALTER TABLE jobs DROP COLUMN program');
        await m.database.customStatement(
          'ALTER TABLE launch_configs DROP COLUMN program',
        );
        // Removed the seeded fake fleet/configs/jobs (real usage now). Deletes
        // only the known seed ids, so user-created rows are untouched.
        await m.database.customStatement(
          "DELETE FROM jobs WHERE id IN ('job-llama-serve', 'job-qwen-eval', "
          "'job-mixtral-batch', 'job-deepseek-test', 'job-phi-profile')",
        );
        await m.database.customStatement(
          "DELETE FROM launch_configs WHERE id IN ('cfg-llama-70b', "
          "'cfg-qwen-coder', 'cfg-mixtral')",
        );
        await m.database.customStatement(
          "DELETE FROM machines WHERE id IN ('orion', 'vega')",
        );
      }
      if (from < 5) await m.createTable(settings);
      if (from < 6) {
        await m.database.customStatement(
          'ALTER TABLE saved_benchmarks ADD COLUMN machine_name TEXT',
        );
      }
      if (from < 7) {
        await m.database.customStatement(
          "ALTER TABLE saved_benchmarks ADD COLUMN samples_json TEXT NOT NULL "
          "DEFAULT '[]'",
        );
      }
      if (from < 8) {
        await m.database.customStatement(
          "ALTER TABLE saved_benchmarks ADD COLUMN command TEXT NOT NULL "
          "DEFAULT ''",
        );
      }
    },
  );
}
