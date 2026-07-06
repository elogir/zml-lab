/// Whitespace-splits [query] into terms and returns true when *every* term is
/// a substring of the combined [fields] (case-insensitive). So "metal qwen 3.5"
/// matches an item whose fields together contain all three, in any order —
/// unlike a single-substring match, which needs that exact phrase.
///
/// An empty (or whitespace-only) query matches everything. Null fields are
/// skipped.
bool matchesSearch(String query, Iterable<String?> fields) {
  final terms = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty);
  if (terms.isEmpty) return true;
  final haystack = fields.whereType<String>().join(' ').toLowerCase();
  return terms.every(haystack.contains);
}
