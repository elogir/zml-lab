// Importing perf run files (.jsonl.gz) into Saved benchmarks: a run
// exported from ZML-Lab comes back with the numbers its saved report had,
// another benchmarker's run reads too, the same file twice is one run, and
// unreadable files are reported.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/database/database.dart';
import 'package:zml_lab/core/database/database_provider.dart';
import 'package:zml_lab/features/perf/domain/chip_metrics.dart';
import 'package:zml_lab/features/perf/domain/csv_events.dart';
import 'package:zml_lab/features/perf/domain/perf_stats.dart';
import 'package:zml_lab/features/perf/domain/run_recorder.dart';
import 'package:zml_lab/features/perf/domain/run_report.dart';
import 'package:zml_lab/features/saved_benchmarks/application/saved_benchmarks_providers.dart';
import 'package:zml_lab/features/saved_benchmarks/domain/saved_entry.dart';
import 'package:zml_lab/models/perf_report.dart';
import 'package:zml_lab/models/run_meta.dart';
import 'package:zml_lab/repositories/perf_report_repository.dart';

const _runId = 'p-1792836000000000';

/// The automatic meta.json of a run against a saved machine, as the Perf
/// tool writes it.
const _autoMeta = <String, Object?>{
  'schema_version': 1,
  'run_id': _runId,
  'label': 'Qwen3-8B · c=4',
  'started_at': '2026-10-24T12:00:00Z',
  'ended_at': '2026-10-24T12:00:31Z',
  'cancelled': false,
  'app': {'benchmarker_api': 2},
  'target': {'url': 'http://10.0.0.5:8000/v1/', 'machine': '4090-box'},
  'server': {'kind': 'zml'},
  'model': {'name': 'Qwen/Qwen3-8B'},
  'hardware': {
    'description': '1× RTX 4090, 64 GB',
    'chips': [
      {'device': 0, 'kind': 'cuda', 'name': 'NVIDIA GeForce RTX 4090'},
    ],
  },
  'params': {
    'duration_s': 30,
    'concurrency': 4,
    'max_completion_tokens': 256,
    'ignore_eos': false,
    'prompts': 'long',
    'turns': 'all',
    'warmup': true,
  },
};

/// zml-smi samples every 500 ms over the run, starting at [t0]: two devices,
/// the second without power readings.
List<(int, List<ChipReading>)> _chipSamples(int t0) => [
  for (var i = 0; i < 8; i++)
    (
      t0 + i * 500000000 + i * i * 3000000,
      [
        ChipReading(
          device: 0,
          kind: 'cuda',
          name: 'NVIDIA GeForce RTX 4090',
          utilPercent: 40 + 7 * i,
          powerW: i == 3 ? null : 120 + 31.5 * i,
          powerLimitW: 450,
          temperatureC: 50 + i,
          memUsedBytes: (10 + i) << 30,
          memTotalBytes: 24 << 30,
        ),
        ChipReading(device: 1, kind: 'cuda', utilPercent: 10 + i),
      ],
    ),
];

/// The report the Perf tool makes of [csv] and [samples] as they stream in
/// (PerfController._finish): the CSV in chunks, the series redrawn as it
/// goes.
PerfReport _liveReport(String csv, List<(int, List<ChipReading>)> samples) {
  final acc = PerfAccumulator();
  final parser = PerfCsvParser();
  for (var i = 0; i < csv.length; i += 4096) {
    acc.addAll(parser.add(csv.substring(i, math.min(i + 4096, csv.length))));
    acc.series(includeLast: true);
  }
  final chips = ChipAccumulator();
  for (final (ts, readings) in samples) {
    chips.add(ts, readings);
  }
  return PerfReport(
    id: _runId,
    name: '4090-box:8000',
    jobName: '4090-box:8000',
    machineName: '4090-box',
    endpoint: '4090-box:8000',
    benchCommand: '',
    createdAt: DateTime.now(),
    params: const PerfParams(
      concurrency: 4,
      maxCompletionTokens: 256,
      model: 'Qwen/Qwen3-8B',
    ),
    totalSeconds: acc.totalSeconds,
    totalEvents: acc.eventCount,
    totalRequests: acc.requestCount,
    tokensPerSecond: acc.tokensPerSecond,
    requestsPerSecond: acc.requestsPerSecond,
    maxSeq: acc.maxSeq,
    errorCount: acc.errorCount,
    errorSample: acc.firstError,
    stats: acc.statRows(),
    series: acc.series(includeLast: true),
    ttftHistogram: acc.ttftHistogram(),
    itlHistogram: acc.itlHistogram(),
    chips: chips.stats(),
    joulesPerToken: chips.joulesPerToken(acc.tokenCount),
  );
}

void main() {
  late Directory tmp;
  late AppDatabase db;
  late ProviderContainer container;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('run_import_test');
    debugRunsDir = '${tmp.path}/runs';
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    debugRunsDir = null;
    container.dispose();
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  PerfReportRepository repo() => container.read(perfReportRepositoryProvider);
  SavedBrowser browser() => container.read(savedBrowserProvider.notifier);
  Future<List<PerfReport>> saved() => repo().watchReports().first;

  /// Records [csv] and [samples] as run [_runId] with [meta], as the Perf
  /// tool does; returns its file.
  Future<String> record(
    String csv,
    List<(int, List<ChipReading>)> samples,
    Map<String, Object?> meta,
  ) async {
    final spool = await RunSpool.create(_runId);
    spool.addEvents(csv);
    for (final (ts, readings) in samples) {
      spool.addChipSample(ts, readings);
    }
    return (await spool.finish(meta))!;
  }

  test('an exported run imports with its saved report\'s numbers', () async {
    final csv = File('test/fixtures/perf_events.csv').readAsStringSync();
    final t0 = PerfCsvParser().add(csv).first.requestTimestampNs;
    final samples = _chipSamples(t0);

    // Run, save with details (written to the run file too), export.
    final runFile = await record(csv, samples, _autoMeta);
    const details = RunDetails(
      label: 'llmd fp8 · c=4',
      model: 'Qwen/Qwen3-8B',
      hardware: '1× RTX 4090 (300 W cap)',
      serverVersion: '0.4.2',
      serverCommit: 'a1b2c3d',
      tags: ['llmd', 'fp8'],
      notes: 'first try',
    );
    await repo().save(_liveReport(csv, samples).withDetails(details));
    final edited = withRunMetaFields(
      _autoMeta,
      changedRunMetaFields(_autoMeta, {
        for (final path in runMetaFields)
          path: runMetaField(details.toMeta(), path),
      }),
    );
    await rewriteRunMeta(runFile, edited);
    final exported = '${tmp.path}/llmd-fp8.jsonl.gz';
    await exportRun(runFile: runFile, meta: edited, out: exported);
    final original = (await saved()).single;

    // Deleted here (as on another machine), then imported back.
    await browser().delete([PerfEntry(original)]);
    expect(runFileExists(_runId), isFalse);
    final result = await browser().importRuns([exported]);
    expect(result.imported, ['llmd fp8 · c=4']);
    expect(result.duplicates, isEmpty);
    expect(result.failed, isEmpty);

    final imported = (await saved()).single;
    expect(imported.id, _runId);
    // Everything measured and described: the stats, series, histograms,
    // chips, energy, params and details all come back as they were saved.
    expect(jsonEncode(imported.toMap()), jsonEncode(original.toMap()));
    expect(imported.name, original.name);
    expect(imported.machineName, original.machineName);
    expect(imported.endpoint, original.endpoint);
    expect(imported.totalRequests, original.totalRequests);
    expect(imported.tokensPerSecond, original.tokensPerSecond);
    expect(imported.requestsPerSecond, original.requestsPerSecond);
    expect(imported.chips, hasLength(2));
    expect(imported.joulesPerToken, isNotNull);
    expect(imported.stats, hasLength(original.stats.length));
    // It's dated by when it ran.
    expect(
      imported.createdAt.isAtSameMomentAs(
        DateTime.utc(2026, 10, 24, 12, 0, 31),
      ),
      isTrue,
    );
    // The file is kept as its recording: Export run and Edit details work.
    expect(runFileExists(_runId), isTrue);
    expect(
      (await readRunMeta(runFilePath(_runId)))!..remove('t0_unix_us'),
      edited,
    );
  });

  test('a run another benchmarker wrote imports too', () async {
    // The least a writer has to say: no conversations or turns, an end
    // after the last chunk (the [DONE]), no usage, no chips.
    final file = '${tmp.path}/vllm-bench.jsonl.gz';
    File(file).writeAsBytesSync(
      gzip.encode(
        utf8.encode(
          '${[
            {'type': 'meta', 'schema_version': 1, 't0_unix_us': 1793000000000000, 'run_id': 'other-1', 'label': 'vLLM bench'},
            {
              'type': 'request',
              'id': 'a',
              'sent_us': 0,
              'end_us': 150000,
              'output_tokens': 3,
              'chunk_us': [100000, 120000, 140000],
              'answer_chars': [1, 1, 1],
              'reasoning_chars': [0, 0, 0],
            },
            {
              'type': 'request',
              'id': 'b',
              'sent_us': 10000,
              'end_us': 300000,
              'output_tokens': 2,
              'error': 'boom',
              'chunk_us': [210000, 260000],
              'answer_chars': [2, 0],
              'reasoning_chars': [0, 3],
            },
          ].map(jsonEncode).join('\n')}\n',
        ),
      ),
    );

    final result = await browser().importRuns([file]);
    expect(result.failed, isEmpty);
    final report = (await saved()).single;
    expect(report.name, 'vLLM bench');
    expect(report.totalRequests, 2);
    expect(report.errorCount, 1);
    // First tokens 100 and 200 ms after their requests; gaps 20, 20, 50 ms.
    expect(report.stat('Time to first token')!.p50, closeTo(150, 1e-9));
    expect(report.stat('Inter-token latency')!.p50, closeTo(20, 1e-9));
    // 5 tokens from the first request to the last moment, the error at 0.3 s.
    expect(report.tokensPerSecond, closeTo(5 / 0.3, 1e-9));
  });

  test('the same run twice is saved once', () async {
    final csv = File('test/fixtures/perf_events.csv').readAsStringSync();
    final file = await record(csv, const [], _autoMeta);
    final copy = '${tmp.path}/again.jsonl.gz';
    File(file).copySync(copy);

    final first = await browser().importRuns([file]);
    expect(first.imported, ['Qwen3-8B · c=4']);
    final second = await browser().importRuns([copy, file]);
    expect(second.imported, isEmpty);
    expect(second.duplicates, ['Qwen3-8B · c=4', 'Qwen3-8B · c=4']);
    expect(second.failed, isEmpty);
    expect([for (final r in await saved()) r.id], [_runId]);
  });

  test('files that can\'t be imported are reported; the rest go in', () async {
    final notGzip = File('${tmp.path}/notes.jsonl.gz')
      ..writeAsStringSync('not a run file');
    final noMeta = File('${tmp.path}/plain.jsonl.gz')
      ..writeAsBytesSync(gzip.encode(utf8.encode('{"type":"request"}\n')));
    final v2 = File('${tmp.path}/v2.jsonl.gz')
      ..writeAsBytesSync(
        gzip.encode(
          utf8.encode(
            '{"type":"meta","schema_version":2,"t0_unix_us":0,"run_id":"x"}\n',
          ),
        ),
      );
    final csv = File('test/fixtures/perf_events.csv').readAsStringSync();
    final noRunId = '${tmp.path}/no-id.jsonl.gz';
    File(await record(csv, const [], const {})).renameSync(noRunId);
    final good = await record(csv, const [], _autoMeta);

    final result = await browser().importRuns([
      notGzip.path,
      noMeta.path,
      v2.path,
      noRunId,
      good,
    ]);
    expect(result.imported, ['Qwen3-8B · c=4']);
    expect(
      [for (final (file, _) in result.failed) file],
      ['notes.jsonl.gz', 'plain.jsonl.gz', 'v2.jsonl.gz', 'no-id.jsonl.gz'],
    );
    expect(result.failed[0].$2, contains('not a run file'));
    expect(result.failed[1].$2, contains('not a run file'));
    expect(result.failed[2].$2, contains('not a run file'));
    expect(result.failed[3].$2, contains('run_id'));
    expect([for (final r in await saved()) r.id], [_runId]);
  });

  test('a run without a label or machine still gets a name', () {
    const ms = 1000000;
    final rows = RunRows(
      events: PerfCsvParser().add(
        'timestamp,request_id,seq,token,request_timestamp,inputs_tokens,'
        'outputs_tokens,concurrency,server,session_id,error\n'
        '${1000 * ms},c0-0,0,hi,${900 * ms},0,1,1,zml,s,\n'
        '${1020 * ms},c0-0,1,!,${900 * ms},12,2,1,zml,s,\n',
      ),
      chips: const [],
    );
    final when = DateTime(2026, 10, 25);
    final report = reportFromRun(
      {
        'schema_version': 1,
        'run_id': 'web-1',
        'target': {'url': 'http://gpu-box:8001/v1/'},
        'model': {'name': 'org/Model'},
      },
      rows,
      fallbackName: 'from-the-website',
      fallbackDate: when,
    );
    expect(report.name, 'from-the-website');
    expect(report.machineName, 'gpu-box');
    expect(report.endpoint, 'gpu-box:8001');
    expect(report.displayModel, 'org/Model');
    expect(report.modelAlias, isNull);
    expect(report.createdAt, when);
    expect(report.totalRequests, 1);
    expect(report.stat('Time to first token')!.p50, 100);
    expect(report.stat('Inter-token latency')!.p50, 20);
  });
}
