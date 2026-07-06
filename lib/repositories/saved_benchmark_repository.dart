import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';
import '../models/saved_benchmark.dart';
import 'mappers.dart';

part 'saved_benchmark_repository.g.dart';

/// Stores and observes named benchmark snapshots.
abstract interface class SavedBenchmarkRepository {
  Stream<List<SavedBenchmark>> watchBenchmarks();
  Future<void> save(SavedBenchmark benchmark);
  Future<void> delete(String id);
}

class DriftSavedBenchmarkRepository implements SavedBenchmarkRepository {
  DriftSavedBenchmarkRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<SavedBenchmark>> watchBenchmarks() => (_db.select(
    _db.savedBenchmarks,
  )..orderBy([
    (t) =>
        OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
  ])).watch().map((rows) => rows.map((r) => r.toModel()).toList());

  @override
  Future<void> save(SavedBenchmark b) => _db
      .into(_db.savedBenchmarks)
      .insertOnConflictUpdate(
        SavedBenchmarksCompanion.insert(
          id: b.id,
          name: b.name,
          endpoint: b.endpoint,
          machineName: Value(b.machineName),
          prompt: b.prompt,
          batchSize: b.batchSize,
          aggregateTokensPerSecond: b.aggregateTokensPerSecond,
          completed: b.completed,
          medianTtftMs: b.medianTtftMs,
          elapsedMs: b.elapsedMs,
          createdAt: b.createdAt,
          requestsJson: Value(encodeBenchmarkRequests(b.requests)),
          samplesJson: Value(encodeBenchmarkSamples(b.samples)),
        ),
      );

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.savedBenchmarks)..where((t) => t.id.equals(id))).go();
}

@Riverpod(keepAlive: true)
SavedBenchmarkRepository savedBenchmarkRepository(Ref ref) =>
    DriftSavedBenchmarkRepository(ref.watch(appDatabaseProvider));
