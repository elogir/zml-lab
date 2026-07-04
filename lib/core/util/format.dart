/// Human-readable uptime: `2h 14m`, `41m`, `9s`.
String formatUptime(Duration d) {
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  if (d.inMinutes >= 1) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}

/// `2.0 s`, `340 ms` — for elapsed / latency readouts.
String formatMillis(int ms) =>
    ms >= 1000 ? '${(ms / 1000).toStringAsFixed(1)} s' : '$ms ms';

/// Compact "time since": `just now`, `5m ago`, `3h ago`, `2d ago`.
String formatAgo(DateTime then, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(then);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}
