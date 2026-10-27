// The app's perf statistics against the run format's SQL
// (docs/perf-run-format.md, "Metrics"): the same run is recorded to its
// run file, the doc's definitions run on it in DuckDB, and every number
// must match what PerfAccumulator computed from the stream.
//
// DuckDB is Python's, through uv (as the analyze-zmlrun skill runs it): the
// app doesn't ship it. Without uv these skip.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/perf/domain/chip_metrics.dart';
import 'package:zml_lab/features/perf/domain/csv_events.dart';
import 'package:zml_lab/features/perf/domain/perf_stats.dart';
import 'package:zml_lab/features/perf/domain/run_recorder.dart';

final _uv = Process.runSync('which', ['uv']).stdout.toString().trim();

/// Runs [setup] then each of [queries] in one DuckDB connection; returns
/// each query's rows.
Future<List<List<List<Object?>>>> _duckdb(
  String setup,
  List<String> queries,
) async {
  const script = '''
import duckdb, json, sys
req = json.load(sys.stdin)
con = duckdb.connect()
con.execute(req["setup"])
json.dump([con.execute(q).fetchall() for q in req["queries"]], sys.stdout, default=float)
''';
  final p = await Process.start(_uv, [
    'run',
    '--quiet',
    '--no-project',
    '--with',
    'duckdb>=1.1',
    'python',
    '-c',
    script,
  ]);
  p.stdin.write(jsonEncode({'setup': setup, 'queries': queries}));
  await p.stdin.close();
  final out = p.stdout.transform(utf8.decoder).join();
  final err = p.stderr.transform(utf8.decoder).join();
  if (await p.exitCode != 0) throw StateError('DuckDB: ${await err}');
  return [
    for (final rows in jsonDecode(await out) as List)
      [for (final row in rows as List) (row as List).cast<Object?>()],
  ];
}

// The doc's loading views, verbatim but for the file's name.
String _loadingViews(String file) =>
    '''
CREATE VIEW lines AS
SELECT * FROM read_json('${file.replaceAll("'", "''")}', format = 'newline_delimited', columns = {
  type: 'VARCHAR',
  id: 'VARCHAR', conversation: 'VARCHAR', turn: 'INTEGER',
  sent_us: 'BIGINT', end_us: 'BIGINT',
  input_tokens: 'INTEGER', output_tokens: 'INTEGER', error: 'VARCHAR',
  chunk_us: 'BIGINT[]', answer_chars: 'INTEGER[]', reasoning_chars: 'INTEGER[]',
  t_us: 'BIGINT', device: 'INTEGER', kind: 'VARCHAR', name: 'VARCHAR',
  util_percent: 'INTEGER', power_w: 'DOUBLE', power_limit_w: 'DOUBLE',
  temperature_c: 'INTEGER', mem_used_bytes: 'BIGINT', mem_total_bytes: 'BIGINT',
  clock_graphics_mhz: 'INTEGER', clock_mem_mhz: 'INTEGER',
  pcie_tx_kbps: 'INTEGER', pcie_rx_kbps: 'INTEGER'
});

CREATE VIEW chunks AS
SELECT id AS request_id, sent_us,
       unnest(chunk_us)        AS t_us,
       unnest(answer_chars)    AS answer_chars,
       unnest(reasoning_chars) AS reasoning_chars
FROM lines WHERE type = 'request';

CREATE VIEW chips AS
SELECT t_us, device, kind, name, util_percent, power_w, power_limit_w,
       temperature_c, mem_used_bytes, mem_total_bytes, clock_graphics_mhz,
       clock_mem_mhz, pcie_tx_kbps, pcie_rx_kbps
FROM lines WHERE type = 'chip';
''';

// The doc's metric and time-series views, verbatim.
const _views = '''
CREATE VIEW tokens AS
SELECT * FROM chunks WHERE answer_chars + reasoning_chars > 0;

CREATE VIEW requests AS
SELECT r.id, r.sent_us, c.first_token_us,
       greatest(c.last_chunk_us, r.end_us) AS last_us,
       r.output_tokens, r.input_tokens,
       r.error IS NOT NULL                 AS failed,
       r.end_us IS NOT NULL                AS ended
FROM lines r LEFT JOIN (
  SELECT request_id,
         min(t_us) FILTER (WHERE answer_chars + reasoning_chars > 0) AS first_token_us,
         max(t_us)                                                    AS last_chunk_us
  FROM chunks GROUP BY request_id
) c ON c.request_id = r.id
WHERE r.type = 'request';

CREATE VIEW points AS
WITH t AS (SELECT min(sent_us) AS t0 FROM requests)
SELECT range AS i, t0 + (range + 1) * 100000 AS t_us
FROM t, range((SELECT max(greatest(0, (last_us - t0) // 100000)) + 1
               FROM requests, t));
''';

// The doc's time series, verbatim.
const _throughputSeries = '''
WITH t AS (SELECT min(sent_us) AS t0 FROM requests),
buckets AS (
  SELECT greatest(0, (t_us - t0) // 100000) AS b, count(*) AS tokens
  FROM tokens, t GROUP BY 1
)
SELECT p.i, (p.i + 1) * 100 AS elapsed_ms,
       coalesce(sum(b.tokens), 0) / ((p.i - greatest(0, p.i - 9) + 1) / 10)
         AS tokens_per_second
FROM points p LEFT JOIN buckets b ON b.b BETWEEN greatest(0, p.i - 9) AND p.i
GROUP BY p.i ORDER BY p.i''';

const _inFlightSeries = '''
WITH r AS (
  SELECT sent_us, first_token_us, last_us,
         ended OR NOT (SELECT bool_or(ended) FROM requests) AS ends_at_last
  FROM requests
)
SELECT p.i, (p.i + 1) * 100 AS elapsed_ms,
       count(*) FILTER (WHERE r.sent_us <= p.t_us
                          AND (NOT r.ends_at_last OR p.t_us < r.last_us))
         AS in_flight,
       count(*) FILTER (WHERE r.sent_us <= p.t_us
                          AND (NOT r.ends_at_last OR p.t_us < r.last_us)
                          AND (r.first_token_us IS NULL OR p.t_us < r.first_token_us))
         AS waiting
FROM points p, r
GROUP BY p.i ORDER BY p.i''';

// Each statistic's values, as the doc defines them.
const _values = {
  'Time to first token':
      'SELECT (first_token_us - sent_us) / 1e3 AS v FROM requests '
      'WHERE first_token_us IS NOT NULL',
  'Inter-token latency':
      'SELECT gap_ms AS v FROM ('
      '  SELECT (t_us - lag(t_us) OVER (PARTITION BY request_id '
      '          ORDER BY t_us)) / 1e3 AS gap_ms FROM tokens'
      ') WHERE gap_ms IS NOT NULL',
  'Request latency': 'SELECT (last_us - sent_us) / 1e3 AS v FROM requests',
  'Output sequence length': 'SELECT output_tokens AS v FROM requests',
  'Input sequence length':
      'SELECT input_tokens AS v FROM requests WHERE input_tokens > 0',
};

const _throughput = '''
SELECT (SELECT count(*) FROM tokens) / ((max(last_us) - min(sent_us)) / 1e6) AS tokens_per_second,
       count(*)                      / ((max(last_us) - min(sent_us)) / 1e6) AS requests_per_second
FROM requests''';

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
  final skip = _uv.isEmpty ? 'uv not found (it runs the SQL in DuckDB)' : null;

  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('perf_contract_test');
    debugRunsDir = tmp.path;
  });
  tearDown(() {
    debugRunsDir = null;
    tmp.deleteSync(recursive: true);
  });

  /// [queries] over the recorded run [file], with the doc's views (and
  /// [setup] after them).
  Future<List<List<List<Object?>>>> onRun(
    String file,
    List<String> queries, {
    String setup = '',
  }) => _duckdb('${_loadingViews(file)}$_views$setup', queries);

  /// Records [csv] as a run and runs the doc's SQL on it: per statistic
  /// [avg, min, max, p50, p75, p90, p95, p99, p999], throughput, and the
  /// time series as (elapsed ms, tok/s, in flight, waiting) per point.
  Future<
    (Map<String, List<double>>, List<double>, List<(int, double, int, int)>)
  >
  contract(String csv) async {
    final spool = await RunSpool.create('run');
    spool.addEvents(csv);
    final file = (await spool.finish({}))!;
    final labels = _values.keys.toList();
    final results = await onRun(file, [
      for (final values in _values.values)
        'SELECT avg(v), min(v), max(v), '
            '${[
              for (final q in [0.5, 0.75, 0.9, 0.95, 0.99, 0.999]) 'quantile_cont(v, $q)',
            ].join(', ')} '
            'FROM ($values)',
      _throughput,
      _throughputSeries,
      _inFlightSeries,
    ]);
    final stats = <String, List<double>>{};
    for (final (i, label) in labels.indexed) {
      final row = results[i].single;
      if (row.first == null) continue; // no values: no row in the report
      stats[label] = [for (final v in row) (v! as num).toDouble()];
    }
    final throughput = [
      for (final v in results[labels.length].single) (v! as num).toDouble(),
    ];
    final rates = results[labels.length + 1];
    final inFlight = results[labels.length + 2];
    expect(inFlight, hasLength(rates.length));
    final series = [
      for (final (k, rate) in rates.indexed)
        (
          (rate[1]! as num).toInt(),
          (rate[2]! as num).toDouble(),
          (inFlight[k][2]! as num).toInt(),
          (inFlight[k][3]! as num).toInt(),
        ),
    ];
    return (stats, throughput, series);
  }

  Future<PerfAccumulator> expectParity(String csv) async {
    final acc = PerfAccumulator()..addAll(PerfCsvParser().add(csv));
    final (want, throughput, series) = await contract(csv);
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
    // The charts' series, point by point.
    final points = acc.series(includeLast: true);
    expect(points, hasLength(series.length));
    for (final (i, (elapsedMs, tps, inFlight, waiting)) in series.indexed) {
      final p = points[i];
      expect(p.elapsedMs, elapsedMs, reason: 'point $i');
      expect(p.tps, tps, reason: 'tok/s at point $i');
      expect(p.active, inFlight, reason: 'in flight at point $i');
      expect(p.waiting, waiting, reason: 'waiting at point $i');
    }
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

  test('chips: per device, and energy per token', () async {
    const ms = 1000000;
    // Unevenly spaced samples; device 0 misses a utilization and a power
    // reading, device 1 reports no power at all (so no energy).
    final samples = [
      for (var i = 0; i < 6; i++)
        (
          1000 * ms + i * 500 * ms + i * i * 7 * ms,
          [
            ChipReading(
              device: 0,
              kind: 'cuda',
              name: 'NVIDIA H100 80GB HBM3',
              utilPercent: i == 4 ? null : 10 + 18 * i,
              powerW: i == 5 ? null : 50 + 55.5 * i,
              temperatureC: 40 + 5 * i,
              memUsedBytes: (1 + i) << 30,
              memTotalBytes: 80 << 30,
            ),
            ChipReading(device: 1, kind: 'neuron', utilPercent: 50 + i),
          ],
        ),
    ];
    final csv = _vllmLikeRun();
    final spool = await RunSpool.create('run');
    spool.addEvents(csv);
    final chips = ChipAccumulator();
    for (final (ts, readings) in samples) {
      spool.addChipSample(ts, readings);
      chips.add(ts, readings);
    }
    final file = (await spool.finish({}))!;
    final [rows, [[joulesPerToken]]] = await onRun(file, [
      _chipStats,
      _joulesPerToken,
    ], setup: _energyView);

    final got = chips.stats();
    expect(got, hasLength(rows.length));
    for (final (i, row) in rows.indexed) {
      final s = got[i];
      double? d(Object? v) => (v as num?)?.toDouble();
      int? n(Object? v) => (v as num?)?.toInt();
      expect(s.device, n(row[0]));
      expect(s.name, row[1]);
      expect(s.utilAvg, closeTo(d(row[2])!, 1e-9));
      expect(s.utilMax, n(row[3]));
      if (d(row[4]) case final p?) {
        expect(s.powerAvgW, closeTo(p, 1e-9));
      } else {
        expect(s.powerAvgW, isNull);
      }
      expect(s.powerMaxW, d(row[5]));
      expect(s.temperatureMaxC, n(row[6]));
      expect(s.memPeakBytes, n(row[7]));
      expect(s.memTotalBytes, n(row[8]));
      if (d(row[9]) case final e?) {
        expect(s.energyJ, closeTo(e, 1e-9));
      } else {
        expect(s.energyJ, isNull);
      }
    }
    expect(got[0].energyJ, greaterThan(0));
    expect(got[1].energyJ, isNull);

    final acc = PerfAccumulator()..addAll(PerfCsvParser().add(csv));
    expect(
      chips.joulesPerToken(acc.tokenCount),
      closeTo((joulesPerToken! as num).toDouble(), 1e-12),
    );
  }, skip: skip);

  test('zml-smi is looked for on the target unless told otherwise', () {
    expect(zmlSmiUrl('', 'gpu-box'), 'http://gpu-box:9090');
    expect(zmlSmiUrl('9091', 'gpu-box'), 'http://gpu-box:9091');
    expect(zmlSmiUrl(':9091', '10.0.0.5'), 'http://10.0.0.5:9091');
    expect(zmlSmiUrl('other', 'gpu-box'), 'http://other:9090');
    expect(zmlSmiUrl('other:1234', 'gpu-box'), 'http://other:1234');
    expect(zmlSmiUrl('https://smi.lan/api', 'x'), 'https://smi.lan:9090/api');
    expect(zmlSmiUrl('http://{host}:9095', 'gpu-box'), 'http://gpu-box:9095');
    expect(zmlSmiUrl('[::1]:9091', 'x'), 'http://[::1]:9091');
    // The Settings port is the default; the popover's address overrides it.
    expect(zmlSmiUrl('', 'gpu-box', port: 9200), 'http://gpu-box:9200');
    expect(zmlSmiUrl('other', 'gpu-box', port: 9200), 'http://other:9200');
    expect(zmlSmiUrl(':9091', 'gpu-box', port: 9200), 'http://gpu-box:9091');
  });

  test('chips are described as people name hardware', () {
    ChipReading chip(int i, String? name) =>
        ChipReading(device: i, kind: 'cuda', name: name);
    expect(
      describeChips([chip(0, 'NVIDIA H100'), chip(1, 'NVIDIA H100')]),
      '2× NVIDIA H100',
    );
    expect(describeChips([chip(0, 'A'), chip(1, null)]), '1× A + 1× cuda');
  });
}

// The doc's chip SQL, verbatim.
const _energyView = '''
CREATE VIEW energy AS
SELECT device, sum(j) AS energy_j FROM (
  SELECT device,
         (power_w + lag(power_w) OVER w) / 2 * (t_us - lag(t_us) OVER w) / 1e6 AS j
  FROM chips WHERE power_w IS NOT NULL
  WINDOW w AS (PARTITION BY device ORDER BY t_us)
) GROUP BY device;
''';

const _chipStats = '''
SELECT c.device, any_value(c.name) AS name,
       avg(util_percent) AS util_avg, max(util_percent) AS util_max,
       avg(power_w) AS power_avg_w, max(power_w) AS power_max_w,
       max(temperature_c) AS temperature_max_c,
       max(mem_used_bytes) AS mem_peak_bytes, max(mem_total_bytes) AS mem_total_bytes,
       any_value(e.energy_j) AS energy_j
FROM chips c LEFT JOIN energy e USING (device)
GROUP BY c.device ORDER BY c.device''';

const _joulesPerToken =
    'SELECT sum(energy_j) / (SELECT count(*) FROM tokens) AS joules_per_token '
    'FROM energy';
