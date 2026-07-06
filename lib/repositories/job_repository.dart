import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';
import '../models/enums.dart';
import '../models/job.dart';
import 'mappers.dart';

part 'job_repository.g.dart';

/// Reads/observes jobs and persists their lifecycle. Writes here drive the
/// whole UI: [watchJobs]/[watchJob] are drift `.watch()` streams, so any
/// mutation propagates to the dashboard and detail view automatically.
abstract interface class JobRepository {
  Stream<List<Job>> watchJobs();
  Stream<Job?> watchJob(String id);
  Future<Job?> jobById(String id);
  Future<List<Job>> allJobs();

  /// Inserts or replaces a job (used when launching).
  Future<void> upsertJob(Job job);

  /// Moves a job to [status], optionally setting a new [pid] or clearing it
  /// (on exit). Leaves other columns untouched.
  Future<void> updateJobStatus(
    String id,
    JobStatus status, {
    int? pid,
    bool clearPid = false,
  });

  Future<void> deleteJob(String id);
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

  @override
  Future<List<Job>> allJobs() async =>
      (await _db.select(_db.jobs).get()).map((r) => r.toModel()).toList();

  @override
  Future<void> upsertJob(Job job) =>
      _db.into(_db.jobs).insertOnConflictUpdate(
        JobsCompanion.insert(
          id: job.id,
          name: job.name,
          description: Value(job.description),
          machineId: job.machineId,
          command: job.command,
          workingDir: Value(job.workingDir),
          port: job.port,
          configId: Value(job.configId),
          status: job.status.name,
          envJson: Value(encodeEnv(job.env)),
          pid: Value(job.pid),
          startedAt: Value(job.startedAt),
        ),
      );

  @override
  Future<void> updateJobStatus(
    String id,
    JobStatus status, {
    int? pid,
    bool clearPid = false,
  }) {
    final companion = JobsCompanion(
      status: Value(status.name),
      pid: clearPid ? const Value(null) : (pid == null ? const Value.absent() : Value(pid)),
    );
    return (_db.update(_db.jobs)..where((t) => t.id.equals(id))).write(companion);
  }

  @override
  Future<void> deleteJob(String id) =>
      (_db.delete(_db.jobs)..where((t) => t.id.equals(id))).go();
}

@Riverpod(keepAlive: true)
JobRepository jobRepository(Ref ref) =>
    DriftJobRepository(ref.watch(appDatabaseProvider));
