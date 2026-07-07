import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';
import '../models/perf_report.dart';
import 'mappers.dart';

part 'perf_report_repository.g.dart';

/// Saved perf benchmark reports.
abstract interface class PerfReportRepository {
  Stream<List<PerfReport>> watchReports();
  Future<void> save(PerfReport report);
  Future<void> delete(String id);
}

class DriftPerfReportRepository implements PerfReportRepository {
  DriftPerfReportRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<PerfReport>> watchReports() => (_db.select(
    _db.perfReports,
  )..orderBy([
    (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
  ])).watch().map((rows) => rows.map((r) => r.toModel()).toList());

  @override
  Future<void> save(PerfReport r) => _db
      .into(_db.perfReports)
      .insertOnConflictUpdate(
        PerfReportsCompanion.insert(
          id: r.id,
          name: r.name,
          machineName: r.machineName,
          endpoint: r.endpoint,
          server: r.server,
          createdAt: r.createdAt,
          totalRequests: r.totalRequests,
          tokensPerSecond: r.tokensPerSecond,
          requestsPerSecond: r.requestsPerSecond,
          reportJson: Value(jsonEncode(r.toMap())),
        ),
      );

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.perfReports)..where((t) => t.id.equals(id))).go();
}

@Riverpod(keepAlive: true)
PerfReportRepository perfReportRepository(Ref ref) =>
    DriftPerfReportRepository(ref.watch(appDatabaseProvider));
