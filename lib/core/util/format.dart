/// Human-readable uptime: `2h 14m`, `41m`, `9s`.
String formatUptime(Duration d) {
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  if (d.inMinutes >= 1) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}

/// Bullets in place of an address, when the Blur host setting is on. Matches
/// what a text field with `obscureText` shows, so a read-only slot and an
/// editable field look the same while masked.
String maskHost(String host) => '•' * host.trim().length;

/// `2.0 s`, `340 ms` — for elapsed / latency readouts.
String formatMillis(int ms) =>
    ms >= 1000 ? '${(ms / 1000).toStringAsFixed(1)} s' : '$ms ms';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// When something happened, for lists that span months: [formatAgo] for the
/// past week, then the day — `Oct 12`, or `Oct 12, 2025` in another year.
String formatWhen(DateTime then, {DateTime? now}) {
  now ??= DateTime.now();
  if (now.difference(then).inDays < 7) return formatAgo(then, now: now);
  final day = '${_months[then.month - 1]} ${then.day}';
  return then.year == now.year ? day : '$day, ${then.year}';
}

/// Compact "time since": `just now`, `5m ago`, `3h ago`, `2d ago`.
String formatAgo(DateTime then, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(then);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}
