// Parity test for the perf-stats pipeline: the fixture CSV was produced by
// the real benchmarker (tools/benchmark) against a mock server, and the
// expected numbers below are the output of its own `duckdb/report.sql` on
// that exact CSV (duckdb v1 CLI). If these match, the app's report shows the
// same numbers the CLI pipeline would.
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/perf/domain/csv_events.dart';
import 'package:zml_lab/features/perf/domain/perf_stats.dart';
import 'package:zml_lab/features/perf/domain/report_text.dart';
import 'package:zml_lab/models/perf_report.dart';

// report.sql output (ROUND(x, 2)) for test/fixtures/perf_events.csv:
//                            avg     min    max     p50     p75     p90     p95     p99     p999
const _expected = <String, List<double>>{
  'Time to first token':    [148.87, 54.34, 252.52, 145.81, 188.76, 220.96, 243.99, 251.62, 252.43],
  'Inter-token latency':    [22.57, 0.04, 44.79, 23.31, 33.38, 39.59, 42.01, 44.02, 44.68],
  'Request latency':        [387.48, 170.72, 576.12, 384.21, 427.92, 498.83, 518.78, 561.20, 574.63],
  'Output sequence length': [10.51, 7.0, 14.0, 11.0, 13.0, 14.0, 14.0, 14.0, 14.0],
  'Input sequence length':  [411.15, 30.0, 882.0, 397.5, 611.5, 806.3, 861.9, 880.82, 881.88],
};
const _expectedTokensPerSecond = 116.8277256025044;
const _expectedRequestsPerSecond = 10.166178690089541;
const _expectedRequests = 61;
const _expectedEvents = 701;

double _round2(double v) => (v * 100).roundToDouble() / 100;

void main() {
  final csv = File('test/fixtures/perf_events.csv').readAsStringSync();

  PerfAccumulator accumulate(Iterable<String> chunks) {
    final parser = PerfCsvParser();
    final acc = PerfAccumulator();
    for (final chunk in chunks) {
      acc.addAll(parser.add(chunk));
    }
    return acc;
  }

  test('parses the full record count across arbitrary chunk boundaries', () {
    // The fixture has quoted tokens containing commas, quotes and newlines,
    // so physical lines != records; random chunking stresses carry-over.
    final rng = Random(42);
    final chunks = <String>[];
    var i = 0;
    while (i < csv.length) {
      final n = min(1 + rng.nextInt(97), csv.length - i);
      chunks.add(csv.substring(i, i + n));
      i += n;
    }
    final acc = accumulate(chunks);
    expect(acc.eventCount, _expectedEvents);
    expect(acc.requestCount, _expectedRequests);
    expect(acc.errorCount, 0);
  });

  test('statistics match duckdb report.sql on the same CSV', () {
    final acc = accumulate([csv]);
    final rows = {for (final r in acc.statRows()) r.label: r};
    expect(rows.keys, containsAll(_expected.keys));
    for (final MapEntry(key: label, value: want) in _expected.entries) {
      final row = rows[label]!;
      final got = [
        row.avg, row.min, row.max,
        row.p50, row.p75, row.p90, row.p95, row.p99, row.p999,
      ];
      for (var i = 0; i < want.length; i++) {
        expect(
          _round2(got[i]),
          closeTo(want[i], 0.005),
          reason: '$label column $i',
        );
      }
    }
    expect(
      acc.tokensPerSecond,
      closeTo(_expectedTokensPerSecond, 1e-6),
    );
    expect(
      acc.requestsPerSecond,
      closeTo(_expectedRequestsPerSecond, 1e-6),
    );
  });

  test('series buckets cover the run and sum to the event count', () {
    final acc = accumulate([csv]);
    final series = acc.series(includeLast: true);
    expect(series, isNotEmpty);
    final tokens = series.fold<double>(
      0,
      (sum, p) => sum + p.tps * PerfAccumulator.bucketMs / 1000,
    );
    expect(tokens.round(), _expectedEvents);
    expect(series.last.requests, _expectedRequests);
    final itl = acc.itlHistogram();
    expect(itl.counts.fold<int>(0, (a, b) => a + b), greaterThan(0));
    // Mode 'first': every request has a seq-0 event, so every one lands in
    // the TTFT histogram.
    final ttft = acc.ttftHistogram();
    expect(ttft.counts.fold<int>(0, (a, b) => a + b), _expectedRequests);
  });

  test('CSV export matches duckdb -csv on the same run byte for byte', () {
    final acc = accumulate([csv]);
    final report = PerfReport(
      id: 'test',
      name: 'test',
      jobName: 'test',
      machineName: 'local',
      endpoint: 'local:8901',
      jobCommand: '',
      benchCommand: '',
      server: acc.server,
      createdAt: DateTime(2026),
      params: const PerfParams(),
      totalSeconds: acc.totalSeconds,
      totalEvents: acc.eventCount,
      totalRequests: acc.requestCount,
      tokensPerSecond: acc.tokensPerSecond,
      requestsPerSecond: acc.requestsPerSecond,
      maxSeq: acc.maxSeq,
      errorCount: acc.errorCount,
      stats: acc.statRows(),
      series: acc.series(includeLast: true),
      ttftHistogram: acc.ttftHistogram(),
      itlHistogram: acc.itlHistogram(),
    );
    final reference =
        File('test/fixtures/report_reference.csv').readAsStringSync();
    expect(perfReportCsv(report).trim(), reference.trim());
    // The clipboard table carries the same numbers in duckdb's box layout.
    final table = perfReportTable(report);
    expect(table, contains('│ Time to first token (ms) │ 148.87 │'));
    expect(table, contains('THROUGHPUT'));
    expect(table, contains('116.8277256025044'));
  });
}
