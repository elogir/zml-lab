import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'browser_history.g.dart';

/// Session-wide visited-URL history for the web tabs, most-recent first.
/// Shared across every web pane so the address bar can autocomplete from it.
@Riverpod(keepAlive: true)
class BrowserHistory extends _$BrowserHistory {
  static const _limit = 200;

  @override
  List<String> build() => const [];

  void add(String url) {
    if (url.isEmpty || url.startsWith('about:') || url.startsWith('data:')) {
      return;
    }
    final next = [url, ...state.where((u) => u != url)];
    state = next.length > _limit ? next.sublist(0, _limit) : next;
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
