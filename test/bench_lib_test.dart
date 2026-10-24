import 'dart:convert';
import 'dart:io';

import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:dart_duckdb/open.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/database/database.dart';
import 'package:zml_lab/core/database/database_provider.dart';
import 'package:zml_lab/features/perf/application/perf_controller.dart';
import 'package:zml_lab/features/perf/domain/bench_lib.dart';
import 'package:zml_lab/features/perf/domain/csv_events.dart';
import 'package:zml_lab/features/perf/domain/run_recorder.dart';
import 'package:zml_lab/features/settings/application/settings_controller.dart';
import 'package:zml_lab/models/perf_report.dart';

/// An OpenAI-style streaming endpoint: every request gets [words] content
/// deltas ("w0 ", "w1 ", …) [pace] apart, then a stop and [DONE].
Future<HttpServer> _fakeServer({
  required int words,
  Duration pace = const Duration(milliseconds: 2),
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    await utf8.decoder.bind(req).join();
    final res = req.response
      ..bufferOutput = false
      ..headers.contentType = ContentType('text', 'event-stream');
    String event(Map<String, dynamic> choice) =>
        'data: ${jsonEncode({
          'id': 'x',
          'object': 'chat.completion.chunk',
          'choices': [choice],
        })}\n\n';
    try {
      for (var i = 0; i < words; i++) {
        res.write(
          event({
            'index': 0,
            'delta': {'content': 'w$i, "q"\n'},
          }),
        );
        await res.flush();
        await Future<void>.delayed(pace);
      }
      res.write(event({'index': 0, 'delta': {}, 'finish_reason': 'stop'}));
      res.write('data: [DONE]\n\n');
      await res.close();
    } catch (_) {
      // The benchmarker hung up (stopped mid-run).
    }
  });
  return server;
}

/// A ShareGPT file of [n] two-prompt conversations.
File _dataset(Directory dir, int n) =>
    File('${dir.path}/sharegpt.json')..writeAsStringSync(
      jsonEncode([
        for (var i = 0; i < n; i++)
          {
            'id': 'c$i',
            'conversations': [
              {'from': 'human', 'value': 'hello $i'},
              {'from': 'gpt', 'value': 'hi'},
              {'from': 'human', 'value': 'again'},
            ],
          },
      ]),
    );

/// The DuckDB library the plugin downloads (flutter test runs without the
/// app, so the plugin's linked copy isn't there).
final _libduckdb =
    '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
    'dart_duckdb-1.4.4/macos/Libraries/release/libduckdb.dylib';

final String? libduckdbSkip = File(_libduckdb).existsSync()
    ? null
    : 'libduckdb not downloaded yet (run a macOS build once)';

Future<List<List<Object?>>> duckQuery(String sql) async {
  final db = await duckdb.open(':memory:');
  final conn = await duckdb.connect(db);
  try {
    final r = await conn.query(sql);
    return [for (final row in r.fetchAll()) row.toList()];
  } finally {
    await conn.dispose();
    await db.dispose();
  }
}

void main() {
  // Without the library (not copied into native/) these skip.
  final problem = benchLibProblem();
  final skip = problem != null;
  // ignore: avoid_print
  if (skip) print('skipping bench_lib tests: $problem');
  if (libduckdbSkip == null) {
    open.overrideFor(OperatingSystem.macOS, _libduckdb);
  }

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('bench_lib_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  // Real sockets and the library's own threads: run outside the fake-async
  // test zone, with the test binding's HttpClient mock out of the way.
  Future<T> real<T>(WidgetTester tester, Future<T> Function() body) async {
    final mocked = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = mocked);
    return (await tester.runAsync(body)) as T;
  }

  testWidgets('a run streams the CLI\'s CSV through the callback', (
    tester,
  ) async {
    await real(tester, () async {
      const conversations = 12;
      const words = 20;
      final server = await _fakeServer(words: words);
      addTearDown(() => server.close(force: true));

      final csv = StringBuffer();
      final logs = <String>[];
      final run = startBenchLib(
        BenchLibConfig(
          url: 'http://127.0.0.1:${server.port}/v1/',
          inputFile: _dataset(tmp, conversations).path,
          concurrency: 4,
          maxCompletionTokens: 64,
        ),
        onCsv: csv.write,
        onLog: logs.add,
      );
      final summary = await run.done.timeout(const Duration(seconds: 30));

      expect(summary.error, isNull);
      expect(summary.errors, 0);
      expect(logs, contains('Number of conversations: $conversations'));
      expect(logs, contains('Starting 4 workers'));

      final text = csv.toString();
      expect(
        text.split('\n').first,
        'timestamp,request_id,seq,token,request_timestamp,inputs_tokens,'
        'outputs_tokens,concurrency,server,session_id,error',
      );
      final events = PerfCsvParser().add(text);
      expect(events, hasLength(summary.events));
      // Both human turns of every conversation were sent ("all" mode).
      final requests = events.map((e) => e.requestId).toSet();
      expect(requests, hasLength(conversations * 2));
      expect(requests, containsAll(['c0-0', 'c0-2', 'c11-2']));
      // Quotes, commas and newlines in tokens survived the CSV round trip:
      // one event per streamed chunk, numbered in order.
      for (final id in requests) {
        final seqs = [
          for (final e in events)
            if (e.requestId == id) e.seq,
        ];
        expect(seqs.length, greaterThanOrEqualTo(words), reason: id);
      }
      expect(events.every((e) => e.concurrency == 4), isTrue);
    });
  }, skip: skip);

  testWidgets('stop cancels the run and still delivers what streamed', (
    tester,
  ) async {
    await real(tester, () async {
      final server = await _fakeServer(
        words: 10000,
        pace: const Duration(milliseconds: 5),
      );
      addTearDown(() => server.close(force: true));

      final csv = StringBuffer();
      final run = startBenchLib(
        BenchLibConfig(
          url: 'http://127.0.0.1:${server.port}/v1/',
          inputFile: _dataset(tmp, 50).path,
          concurrency: 8,
        ),
        onCsv: csv.write,
        onLog: (_) {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final stoppedAt = DateTime.now();
      run.stop();
      final summary = await run.done.timeout(const Duration(seconds: 10));

      expect(DateTime.now().difference(stoppedAt).inSeconds, lessThan(3));
      expect(summary.error, isNull);
      // Cancelled requests aren't errors (as with the CLI's Ctrl-C).
      expect(summary.errors, 0);
      final events = PerfCsvParser().add(csv.toString());
      expect(events, hasLength(summary.events));
      expect(events.length, greaterThan(100));
    });
  }, skip: skip);

  testWidgets('the perf tab runs the library to a report', (tester) async {
    await real(tester, () async {
      final server = await _fakeServer(words: 20);
      addTearDown(() => server.close(force: true));
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      // A zml-smi --api stand-in: one GPU.
      final smi = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => smi.close(force: true));
      smi.listen((req) {
        req.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'devices': [
                {
                  'cuda': {
                    'name': 'NVIDIA GeForce RTX 4090',
                    'driver_version': '580.82',
                    'util_percent': 97,
                    'power_mw': 312500,
                  },
                },
              ],
              'processes': [],
            }),
          )
          ..close();
      });
      debugRunsDir = '${tmp.path}/runs';
      addTearDown(() => debugRunsDir = null);

      // Let the settings load from the (empty) database before editing them.
      container.read(settingsControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      container.read(settingsControllerProvider.notifier)
        ..setPerfDatasetPath(_dataset(tmp, 12).path)
        ..setPerfChipMetricsUrl('http://{host}:${smi.port}');

      final provider = perfControllerProvider('t');
      final perf = container.read(provider.notifier)
        ..setParams(
          const PerfParams(
            durationSeconds: 10,
            concurrency: 4,
            maxCompletionTokens: 32,
            warmup: false,
          ),
        );
      expect(await perf.preflight(), isNull);
      await perf
          .start(
            host: '127.0.0.1',
            port: server.port,
            jobName: 'test',
            jobCommand: '',
            machineName: 'local',
            machine: '4090-box',
            hardware: '1× RTX 4090, 64 GB',
          )
          .timeout(const Duration(seconds: 30));

      var run = container.read(provider);
      expect(run.phase, PerfPhase.done, reason: run.message);
      final report = run.report!;
      expect(report.totalRequests, 24);
      expect(report.errorCount, 0);
      expect(report.tokensPerSecond, greaterThan(0));
      expect(report.cancelled, isFalse);
      expect(run.chips, isTrue);

      // The recording: written in the background once the run is done.
      if (libduckdbSkip != null) return;
      for (var i = 0; i < 100 && run.runFile == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        run = container.read(provider);
      }
      final file = run.runFile;
      expect(file, runFilePath(report.id));
      final counts = {
        for (final r in await duckQuery(
          "SELECT source, count(*) FROM read_parquet('$file') GROUP BY 1",
        ))
          r[0]: r[1],
      };
      expect(counts['event'], report.totalEvents);
      expect(counts['chip'], greaterThanOrEqualTo(1));
      final meta = (await readRunMeta(file!))!;
      expect(meta['run_id'], report.id);
      expect(meta['target'], {
        'url': 'http://127.0.0.1:${server.port}/v1/',
        'machine': '4090-box',
      });
      expect(meta['hardware'], {
        'description': '1× RTX 4090, 64 GB',
        'chips': [
          {
            'device': 0,
            'kind': 'cuda',
            'name': 'NVIDIA GeForce RTX 4090',
            'driver_version': '580.82',
          },
        ],
      });
      expect(meta['chip_metrics'], {
        'url': 'http://127.0.0.1:${smi.port}',
        'interval_ms': 500,
      });
      expect((meta['params'] as Map)['concurrency'], 4);
      expect((meta['summary'] as Map)['requests'], 24);

      // Discarding an unsaved run removes its recording.
      perf.discard();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(File(file).existsSync(), isFalse);
    });
  }, skip: skip);

  testWidgets('a missing dataset fails the run', (tester) async {
    await real(tester, () async {
      final run = startBenchLib(
        BenchLibConfig(
          url: 'http://127.0.0.1:9/v1/',
          inputFile: '${tmp.path}/nope.json',
        ),
        onCsv: (_) {},
        onLog: (_) {},
      );
      final summary = await run.done.timeout(const Duration(seconds: 10));
      expect(summary.error, contains('Error reading file'));
      expect(summary.events, 0);
    });
  }, skip: skip);
}
