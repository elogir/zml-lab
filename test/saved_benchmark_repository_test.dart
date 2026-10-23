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
    expect(saved.maxTokens, 256);
    expect(saved.temperature, 0.7);
  }

  test('saved runs round-trip their request settings (fresh database)', () {
    return roundTrip(AppDatabase(NativeDatabase.memory()));
  });

  test('the v12 upgrade adds the columns to an existing v11 table', () {
    return roundTrip(
      AppDatabase(
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
              )''');
            raw.execute('PRAGMA user_version = 11');
          },
        ),
      ),
    );
  });
}
