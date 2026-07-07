/// Renders a perf report the way the CLI pipeline prints it, so results can
/// be pasted anywhere the team already quotes benchmarker numbers:
///  - [perfReportTable]: the duckdb box tables (`… | duckdb -c '.read
///    duckdb/report.sql'`), for the clipboard.
///  - [perfReportCsv]: the same two tables as `duckdb -csv` emits them, for
///    file export.
library;

import '../../../models/perf_report.dart';

/// report.sql's row names (the app displays the unit separately).
String _toolLabel(PerfStatRow r) => switch (r.label) {
  'Time to first token' => 'Time to first token (ms)',
  'Inter-token latency' => 'Inter token latency (ms)',
  'Request latency' => 'Request latency (ms)',
  _ => r.label,
};

/// duckdb's rendering of ROUND(x, 2): at least one decimal, at most two,
/// no trailing zero on the second (7 → 7.0, 561.2 → 561.2, 148.87 → 148.87).
String _round2(double v) {
  var s = ((v * 100).round() / 100).toStringAsFixed(2);
  if (s.endsWith('0')) s = s.substring(0, s.length - 1);
  return s;
}

List<String> _statCells(PerfStatRow r) => [
  for (final v in [r.avg, r.min, r.max, ...r.percentiles]) _round2(v),
];

const _statHeaders = [
  'Statistic', 'avg', 'min', 'max',
  'p50', 'p75', 'p90', 'p95', 'p99', 'p999',
];

List<String> _throughputCells(PerfReport r) => [
  '${r.tokensPerSecond}',
  '${r.requestsPerSecond}',
  '${r.totalRequests}',
  '${r.maxSeq}',
];

const _throughputHeaders = [
  'tokens_per_second', 'requests_per_second', 'total', 'max_seq',
];

/// One duckdb-style box table. [leftAlign] marks text columns (data cells
/// left-aligned); the rest are numeric (right-aligned). Headers and the type
/// row are centered, as duckdb prints them.
String _box({
  required List<String> headers,
  required List<String> types,
  required List<List<String>> rows,
  required List<bool> leftAlign,
}) {
  final n = headers.length;
  final widths = List.generate(n, (i) {
    var w = headers[i].length;
    if (types[i].length > w) w = types[i].length;
    for (final row in rows) {
      if (row[i].length > w) w = row[i].length;
    }
    return w + 2; // one space of breathing room each side
  });

  String line(String left, String fill, String mid, String right) =>
      '$left${[for (final w in widths) fill * w].join(mid)}$right';
  String centered(String s, int w) {
    final pad = w - s.length;
    final l = pad ~/ 2;
    return '${' ' * l}$s${' ' * (pad - l)}';
  }

  String cells(List<String> row, {bool center = false}) => '│${[
    for (var i = 0; i < n; i++)
      center
          ? centered(row[i], widths[i])
          : leftAlign[i]
          ? ' ${row[i].padRight(widths[i] - 1)}'
          : '${row[i].padLeft(widths[i] - 1)} ',
  ].join('│')}│';

  return [
    line('┌', '─', '┬', '┐'),
    cells(headers, center: true),
    cells(types, center: true),
    line('├', '─', '┼', '┤'),
    for (final row in rows) cells(row),
    line('└', '─', '┴', '┘'),
  ].join('\n');
}

/// The report as the tool's own pipeline prints it to the terminal.
String perfReportTable(PerfReport r) {
  final stats = _box(
    headers: _statHeaders,
    types: ['varchar', ...List.filled(9, 'double')],
    rows: [
      for (final row in r.stats) [_toolLabel(row), ..._statCells(row)],
    ],
    leftAlign: [true, ...List.filled(9, false)],
  );
  final throughput = _box(
    headers: _throughputHeaders,
    types: const ['double', 'double', 'int64', 'int64'],
    rows: [_throughputCells(r)],
    leftAlign: List.filled(4, false),
  );
  return '$stats\n\nTHROUGHPUT\n$throughput';
}

/// The report as `duckdb -csv` emits it: the statistics table, then the
/// throughput table, each with its own header row.
String perfReportCsv(PerfReport r) => [
  _statHeaders.join(','),
  for (final row in r.stats) [_toolLabel(row), ..._statCells(row)].join(','),
  _throughputHeaders.join(','),
  _throughputCells(r).join(','),
  '',
].join('\n');
