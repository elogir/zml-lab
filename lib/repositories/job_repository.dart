import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';
import '../models/job.dart';
import 'mappers.dart';

part 'job_repository.g.dart';

/// Reads/observes jobs. Mutations (kill/restart/launch) are deferred.
abstract interface class JobRepository {
  Stream<List<Job>> watchJobs();
  Stream<Job?> watchJob(String id);
  Future<Job?> jobById(String id);
}

class DriftJobRepository implements JobRepository {
  DriftJobRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Job>> watchJobs() => (_db.select(
    _db.jobs,
  )..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc)]))
      .watch()
      .map((rows) => rows.map((r) => r.toModel()).toList());

  @override
  Stream<Job?> watchJob(String id) =>
      (_db.select(_db.jobs)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((r) => r?.toModel());

  @override
  Future<Job?> jobById(String id) async {
    final row = await (_db.select(
      _db.jobs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }
}

@Riverpod(keepAlive: true)
JobRepository jobRepository(Ref ref) =>
    DriftJobRepository(ref.watch(appDatabaseProvider));
