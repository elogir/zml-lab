import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// The app's single SQLite database (via drift). Starts empty — the local
/// machine is added at startup (`ensureLocalMachine`); everything else is
/// created by the user.
@DriftDatabase(
  tables: [
    Machines,
    BrowserHistoryEntries,
    SavedBenchmarks,
    PerfReports,
    Settings,
    ApiEndpoints,
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
  int get schemaVersion => 16;

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
        await m.database.customStatement(
          'ALTER TABLE jobs DROP COLUMN program',
        );
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
      if (from < 9) {
        await m.database.customStatement(
          'ALTER TABLE jobs ADD COLUMN config_id TEXT',
        );
      }
      if (from < 10) await m.createTable(perfReports);
      if (from < 11) {
        // Jobs and saved launch configs were removed from the app (processes
        // are now started from the Benchmark tab's terminals).
        await m.database.customStatement('DROP TABLE IF EXISTS jobs');
        await m.database.customStatement('DROP TABLE IF EXISTS launch_configs');
      }
      // From here on, steps are idempotent: an older build opening the same
      // file "downgrades" user_version without undoing anything, so these can
      // run again over a schema that already has them.
      if (from < 12) {
        // Saved runs keep their request settings, for "Copy results".
        final have = await _columns('saved_benchmarks');
        for (final col in [
          savedBenchmarks.model,
          savedBenchmarks.maxTokens,
          savedBenchmarks.temperature,
        ]) {
          if (!have.contains(col.name)) {
            await m.addColumn(savedBenchmarks, col);
          }
        }
      }
      // CREATE TABLE IF NOT EXISTS.
      if (from < 13) await m.createTable(apiEndpoints);
      if (from < 14) {
        // Machines lost their ssh settings: terminals stay local, and the
        // reachability dot pings.
        final have = await _columns('machines');
        for (final col in ['ssh_port', 'user', 'ssh_key']) {
          if (have.contains(col)) {
            await m.database.customStatement(
              'ALTER TABLE machines DROP COLUMN "$col"',
            );
          }
        }
      }
      if (from < 15) {
        // Saved runs record whether they ignored EOS.
        if (!(await _columns(
          'saved_benchmarks',
        )).contains(savedBenchmarks.ignoreEos.name)) {
          await m.addColumn(savedBenchmarks, savedBenchmarks.ignoreEos);
        }
      }
      if (from < 16) {
        // Perf reports no longer keep the server's kind (from its Server
        // header): nothing is keyed on server names.
        if ((await _columns('perf_reports')).contains('server')) {
          await m.database.customStatement(
            'ALTER TABLE perf_reports DROP COLUMN server',
          );
        }
      }
    },
  );

  Future<Set<String>> _columns(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return {for (final r in rows) r.read<String>('name')};
  }
}
