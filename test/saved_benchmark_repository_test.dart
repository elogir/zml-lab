import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/database/database.dart';
import 'package:zml_lab/models/saved_benchmark.dart';
import 'package:zml_lab/repositories/saved_benchmark_repository.dart';

void main() {
  Future<void> roundTrip(AppDatabase db) async {
    addTearDown(db.close);
    final repo = DriftSavedBenchmarkRepository(db);

    await repo.save(
      SavedBenchmark(
        id: 'b-1',
        name: 'run',
        endpoint: 'orion:8000',
        prompt: 'hi',
        model: 'Qwen/Qwen3-8B',
        modelAlias: 'Qwen3 8B',
        hardware: '1× RTX 4090',
        serverVersion: '0.11.0',
        serverCommit: '1a2b3c',
        tags: const ['fp8', 'llmd'],
        notes: 'flash-attn on',
        maxTokens: 256,
        temperature: 0.7,
        batchSize: 4,
        aggregateTokensPerSecond: 100,
        completed: 4,
        medianTtftMs: 120,
        elapsedMs: 2000,
        createdAt: DateTime(2026, 10, 23),
      ),
    );

    final saved = (await repo.watchBenchmarks().first).single;
    expect(saved.model, 'Qwen/Qwen3-8B');
    expect(saved.modelAlias, 'Qwen3 8B');
    expect(saved.displayModel, 'Qwen3 8B');
    expect(saved.hardware, '1× RTX 4090');
    expect(saved.serverVersion, '0.11.0');
    expect(saved.serverCommit, '1a2b3c');
    expect(saved.tags, ['fp8', 'llmd']);
    expect(saved.notes, 'flash-attn on');
    expect(saved.maxTokens, 256);
    expect(saved.temperature, 0.7);
  }

  test('saved runs round-trip their request settings (fresh database)', () {
    return roundTrip(AppDatabase(NativeDatabase.memory()));
  });

  /// A database at user_version 11; [newer] adds what v12/v13 would have.
  AppDatabase v11({bool newer = false}) => AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        // saved_benchmarks as schema v11 left it.
        raw.execute('''
          CREATE TABLE saved_benchmarks (
            id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
            endpoint TEXT NOT NULL, machine_name TEXT,
            command TEXT NOT NULL DEFAULT '', prompt TEXT NOT NULL,
            batch_size INTEGER NOT NULL,
            aggregate_tokens_per_second REAL NOT NULL,
            completed INTEGER NOT NULL, median_ttft_ms INTEGER NOT NULL,
            elapsed_ms INTEGER NOT NULL, created_at INTEGER NOT NULL,
            requests_json TEXT NOT NULL DEFAULT '[]',
            samples_json TEXT NOT NULL DEFAULT '[]'
            ${newer ? ', model TEXT, max_tokens INTEGER, temperature REAL' : ''}
          )''');
        if (newer) {
          raw.execute('''
            CREATE TABLE api_endpoints (
              id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
              base_url TEXT NOT NULL, has_api_key INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            )''');
        }
        raw.execute('PRAGMA user_version = 11');
      },
    ),
  );

  // The v11 table still has the `command` column, which the app no longer
  // writes: inserts leave it to its default.
  test('the upgrades add the columns to an existing v11 table', () {
    return roundTrip(v11());
  });

  test('upgrading again after an older build opened the file', () {
    // An older build "downgrades" user_version but leaves the schema as is:
    // the upgrade has to cope with columns and tables that already exist.
    return roundTrip(v11(newer: true));
  });
}
