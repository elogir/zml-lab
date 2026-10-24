// The app's perf statistics against the run format's SQL
// (docs/perf-run-format.md, "Metrics"): the same run is recorded to its
// Parquet file, the doc's definitions run on it in DuckDB, and every number
// must match what PerfAccumulator computed from the stream.
import 'dart:io';

import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:dart_duckdb/open.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/perf/domain/csv_events.dart';
import 'package:zml_lab/features/perf/domain/perf_stats.dart';
import 'package:zml_lab/features/perf/domain/run_recorder.dart';

/// The DuckDB library the plugin downloads (flutter test runs without the
/// app, so the plugin's linked copy isn't there).
final _libduckdb =
    '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
    'dart_duckdb-1.4.4/macos/Libraries/release/libduckdb.dylib';

// The doc's views, verbatim.
const _views = '''
CREATE VIEW tokens AS
SELECT * FROM events WHERE token_chars + reasoning_chars > 0;

CREATE VIEW requests AS
SELECT request_id,
       min(request_ts_ns)                                               AS sent_ns,
       min(ts_ns) FILTER (WHERE token_chars + reasoning_chars > 0)      AS first_token_ns,
       max(ts_ns)                                                       AS last_ns,
       max(output_tokens)                                               AS output_tokens,
       max(input_tokens)                                                AS input_tokens,
       bool_or(error <> '')                                             AS failed
FROM events GROUP BY request_id;
''';

// Each statistic's values, as the doc defines them.
const _values = {
  'Time to first token':
      'SELECT (first_token_ns - sent_ns) / 1e6 AS v FROM requests '
      'WHERE first_token_ns IS NOT NULL',
  'Inter-token latency':
      'SELECT gap_ms AS v FROM ('
      '  SELECT (ts_ns - lag(ts_ns) OVER (PARTITION BY request_id '
      '          ORDER BY ts_ns)) / 1e6 AS gap_ms FROM tokens'
      ') WHERE gap_ms IS NOT NULL',
  'Request latency': 'SELECT (last_ns - sent_ns) / 1e6 AS v FROM requests',
  'Output sequence length': 'SELECT output_tokens AS v FROM requests',
  'Input sequence length':
      'SELECT input_tokens AS v FROM requests WHERE input_tokens > 0',
};

const _throughput = '''
SELECT (SELECT count(*) FROM tokens)
         / ((max(ts_ns) - min(request_ts_ns)) / 1e9) AS tokens_per_second,
       count(DISTINCT request_id)
         / ((max(ts_ns) - min(request_ts_ns)) / 1e9) AS requests_per_second
FROM events''';

String _field(Object v) {
  final s = '$v';
  return s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

/// A run as vLLM streams it, from a benchmarker with the reasoning column:
/// every request opens with an empty role chunk and ends with an empty
/// finish chunk and a usage chunk; c0 reasons before answering; seq keeps
/// counting across a conversation's turns; c2-0 fails before any text.
String _vllmLikeRun() {
  const ms = 1000000;
  final rows = [
    'timestamp,request_id,seq,token,request_timestamp,inputs_tokens,'
        'outputs_tokens,concurrency,server,session_id,error,reasoning',
  ];
  var sent = 1000 * ms;
  for (final c in [0, 1]) {
    var seq = 0;
    for (final turn in [0, 2]) {
      final id = 'c$c-$turn';
      var out = 0;
      void chunk(
        int atMs, {
        String token = '',
        String reasoning = '',
        bool choice = true,
        int input = 0,
      }) {
        if (choice) out++;
        rows.add(
          [
            sent + atMs * ms,
            id,
            seq++,
            token,
            sent,
            input,
            out,
            4,
            'vllm',
            's',
            '',
            reasoning,
          ].map(_field).join(','),
        );
      }

      // Later turns carry more context: a slower first token.
      final first = turn == 0 ? 80 + 20 * c : 300 + 20 * c;
      chunk(5); // role
      if (c == 0) {
        for (var i = 0; i < 3; i++) {
          chunk(first + 15 * i, reasoning: 'thinking $i, "carefully"\n');
        }
      }
      final answer = c == 0 ? first + 45 : first;
      for (var i = 0; i < 4; i++) {
        chunk(
          answer + 22 * i + i * i,
          token: i == 0 ? 'Hello, "world"' : ' w$i',
        );
      }
      chunk(answer + 200); // finish
      chunk(answer + 201, choice: false, input: 40 + 10 * c + turn); // usage
      sent += 37 * ms;
    }
  }
  rows.add(
    [
      sent + 50 * ms,
      'c2-0',
      0,
      '',
      sent,
      0,
      0,
      4,
      'vllm',
      's',
      'reset',
      '',
    ].map(_field).join(','),
  );
  return '${rows.join('\n')}\n';
}

void main() {
  final skip = !File(_libduckdb).existsSync()
      ? 'libduckdb not downloaded yet (run a macOS build once)'
      : null;

  late Directory tmp;
  setUpAll(() => open.overrideFor(OperatingSystem.macOS, _libduckdb));
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('perf_contract_test');
    debugRunsDir = tmp.path;
  });
  tearDown(() {
    debugRunsDir = null;
    tmp.deleteSync(recursive: true);
  });

  /// Records [csv] as a run and runs the doc's SQL on it: per statistic
  /// [avg, min, max, p50, p75, p90, p95, p99, p999], plus throughput.
  Future<(Map<String, List<double>>, List<double>)> contract(String csv) async {
    final spool = await RunSpool.create('run');
    spool.addEvents(csv);
    final file = (await spool.finish({'schema_version': 1}))!;
    final db = await duckdb.open(':memory:');
    final conn = await duckdb.connect(db);
    try {
      await conn.execute(
        'CREATE VIEW events AS SELECT * FROM '
        "read_parquet('$file') WHERE source = 'event'",
      );
      await conn.execute(_views);
      Future<List<Object?>> one(String sql) async =>
          (await conn.query(sql)).fetchAll().single.toList();
      final stats = <String, List<double>>{};
      for (final MapEntry(key: label, value: values) in _values.entries) {
        final row = await one(
          'SELECT avg(v), min(v), max(v), '
          '${[
            for (final q in [0.5, 0.75, 0.9, 0.95, 0.99, 0.999]) 'quantile_cont(v, $q)',
          ].join(', ')} '
          'FROM ($values)',
        );
        if (row.first == null) continue; // no values: no row in the report
        stats[label] = [for (final v in row) (v! as num).toDouble()];
      }
      final throughput = [
        for (final v in await one(_throughput)) (v! as num).toDouble(),
      ];
      return (stats, throughput);
    } finally {
      await conn.dispose();
      await db.dispose();
    }
  }

  Future<PerfAccumulator> expectParity(String csv) async {
    final acc = PerfAccumulator()..addAll(PerfCsvParser().add(csv));
    final (want, throughput) = await contract(csv);
    final got = {
      for (final r in acc.statRows())
        r.label: [r.avg, r.min, r.max, ...r.percentiles],
    };
    expect(got.keys, unorderedEquals(want.keys));
    for (final MapEntry(key: label, value: values) in want.entries) {
      for (var i = 0; i < values.length; i++) {
        expect(
          got[label]![i],
          closeTo(values[i], 1e-6),
          reason: '$label column $i',
        );
      }
    }
    expect(acc.tokensPerSecond, closeTo(throughput[0], 1e-6));
    expect(acc.requestsPerSecond, closeTo(throughput[1], 1e-6));
    return acc;
  }

  test('a run from the benchmarker (no reasoning column)', () async {
    await expectParity(
      File('test/fixtures/perf_events.csv').readAsStringSync(),
    );
  }, skip: skip);

  test('role chunks, reasoning and later turns', () async {
    final acc = await expectParity(_vllmLikeRun());
    final rows = {for (final r in acc.statRows()) r.label: r};
    // Every turn has a TTFT (not just seq 0's), timed to its first text:
    // the reasoning for c0, the answer for c1 — never the 5 ms role chunk.
    expect(acc.ttftHistogram().counts.fold<int>(0, (a, b) => a + b), 4);
    expect(rows['Time to first token']!.min, 80);
    expect(rows['Time to first token']!.max, 320);
    // Gaps run between text chunks only (reasoning → answer is 15 ms, the
    // answer's 23–27 ms); the 125 ms to the empty finish chunk isn't one.
    expect(rows['Inter-token latency']!.min, 15);
    expect(rows['Inter-token latency']!.max, 27);
    // Every chunk is still an event: c0's turns are role, 3 reasoning,
    // 4 answer, finish and usage; c1's have no reasoning; then c2's error.
    expect(acc.eventCount, 2 * 10 + 2 * 7 + 1);
  }, skip: skip);
}
