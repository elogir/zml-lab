import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/database/database.dart';
import '../core/database/database_provider.dart';

part 'browser_history_repository.g.dart';

/// Persists the web-tab visited-URL history so it survives restarts.
abstract interface class BrowserHistoryRepository {
  /// Most-recent-first, capped.
  Future<List<String>> recent({int limit = 200});

  /// Records a visit to [url] (upserts its timestamp to now).
  Future<void> record(String url);

  /// Removes [url] from history.
  Future<void> remove(String url);
}

class DriftBrowserHistoryRepository implements BrowserHistoryRepository {
  DriftBrowserHistoryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<String>> recent({int limit = 200}) async {
    final rows =
        await (_db.select(_db.browserHistoryEntries)
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.visitedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(limit))
            .get();
    return rows.map((r) => r.url).toList();
  }

  @override
  Future<void> record(String url) => _db
      .into(_db.browserHistoryEntries)
      .insertOnConflictUpdate(
        BrowserHistoryEntriesCompanion.insert(
          url: url,
          visitedAt: DateTime.now(),
        ),
      );

  @override
  Future<void> remove(String url) =>
      (_db.delete(_db.browserHistoryEntries)
            ..where((t) => t.url.equals(url)))
          .go();
}

@Riverpod(keepAlive: true)
BrowserHistoryRepository browserHistoryRepository(Ref ref) =>
    DriftBrowserHistoryRepository(ref.watch(appDatabaseProvider));
