import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../repositories/browser_history_repository.dart';

part 'browser_history.g.dart';

/// Visited-URL history for the web tabs' address bar, most-recent first.
/// Backed by drift so it persists across restarts; the in-memory list is a
/// live cache kept in sync as pages are visited.
@Riverpod(keepAlive: true)
class BrowserHistory extends _$BrowserHistory {
  static const _limit = 200;

  @override
  List<String> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    state = await ref
        .read(browserHistoryRepositoryProvider)
        .recent(limit: _limit);
  }

  void add(String url) {
    if (url.isEmpty || url.startsWith('about:') || url.startsWith('data:')) {
      return;
    }
    final next = [url, ...state.where((u) => u != url)];
    state = next.length > _limit ? next.sublist(0, _limit) : next;
    ref.read(browserHistoryRepositoryProvider).record(url);
  }

  void remove(String url) {
    state = state.where((u) => u != url).toList();
    ref.read(browserHistoryRepositoryProvider).remove(url);
  }

  /// History entries matching [query] (case-insensitive substring), or the most
  /// recent entries when the query is empty. Capped for a tidy dropdown.
  List<String> suggestions(String query) {
    final q = query.trim().toLowerCase();
    final matches = q.isEmpty
        ? state
        : state.where((u) => u.toLowerCase().contains(q));
    return matches.take(5).toList();
  }
}
