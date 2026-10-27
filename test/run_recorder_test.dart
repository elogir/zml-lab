import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/perf/domain/csv_events.dart';
import 'package:zml_lab/features/perf/domain/run_recorder.dart';

void main() {
  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('run_recorder_test');
    debugRunsDir = tmp.path;
  });
  tearDown(() {
    debugRunsDir = null;
    tmp.deleteSync(recursive: true);
  });

  List<Map<String, Object?>> lines(String file) => [
    for (final l in const LineSplitter().convert(
      utf8.decode(gzip.decode(File(file).readAsBytesSync())),
    ))
      (jsonDecode(l) as Map).cast<String, Object?>(),
  ];

  // The benchmarker's CSV, awkward tokens included: commas, quotes,
  // newlines, non-ASCII, an empty role chunk, an error row.
  const csv =
      'timestamp,request_id,seq,token,request_timestamp,inputs_tokens,'
      'outputs_tokens,concurrency,server,session_id,error\n'
      '1000200000,c0-0,0,,1000000000,0,1,16,zml,s,\n'
      '1000300000,c0-0,1,"Hello, ""world""",1000000000,0,2,16,zml,s,\n'
      '1000400000,c0-0,2,"two\nlines",1000000000,0,3,16,zml,s,\n'
      '1000500000,c0-0,3,café,1000000000,42,4,16,zml,s,\n'
      '1000600000,c1-0,0,,1000100000,0,0,16,zml,s,connection reset\n';

  test('a run becomes one gzipped JSON Lines file: meta, requests, '
      'chips', () async {
    final spool = await RunSpool.create('p-1');
    // Chunks are cut anywhere, mid-row included.
    spool
      ..addEvents(csv.substring(0, 150))
      ..addEvents(csv.substring(150))
      ..addChipSample(1000250000, const [
        ChipReading(
          device: 0,
          kind: 'cuda',
          name: 'NVIDIA "RTX" 4090',
          utilPercent: 97,
          powerW: 312.5,
          memUsedBytes: 20000000000,
        ),
      ]);
    final path = await spool.finish({'schema_version': 0, 'label': 'é ’ x'});

    expect(path, runFilePath('p-1'));
    expect(path, endsWith('/p-1.jsonl.gz'));
    expect(Directory('${tmp.path}/.spool/p-1').existsSync(), isFalse);

    // Times in µs since the first request was sent; in time order; no
    // token text, only its length (in code points: café is 4).
    expect(lines(path!), [
      {
        'type': 'meta',
        'schema_version': 1,
        't0_unix_us': 1000000,
        'label': 'é ’ x',
      },
      {
        'type': 'request',
        'id': 'c0-0',
        'conversation': 'c0',
        'turn': 0,
        'sent_us': 0,
        'end_us': 500,
        'input_tokens': 42,
        'output_tokens': 4,
        'error': null,
        'chunk_us': [200, 300, 400, 500],
        'answer_chars': [0, 14, 9, 4], // "", Hello, "world", two\nlines, café
        'reasoning_chars': [0, 0, 0, 0],
      },
      {
        'type': 'request',
        'id': 'c1-0',
        'conversation': 'c1',
        'turn': 0,
        'sent_us': 100,
        'end_us': 600,
        'input_tokens': null,
        'output_tokens': 0,
        'error': 'connection reset',
        'chunk_us': <int>[],
        'answer_chars': <int>[],
        'reasoning_chars': <int>[],
      },
      {
        'type': 'chip',
        't_us': 250,
        'device': 0,
        'kind': 'cuda',
        'name': 'NVIDIA "RTX" 4090',
        'util_percent': 97,
        'power_w': 312.5,
        'mem_used_bytes': 20000000000,
      },
    ]);
    expect(await readRunMeta(path), {
      'schema_version': 1,
      't0_unix_us': 1000000,
      'label': 'é ’ x',
    });
  });

  test('reading a run gives back the events and chip samples it '
      'recorded', () async {
    final spool = await RunSpool.create('p-4');
    spool
      ..addEvents(csv)
      ..addChipSample(1000250000, const [
        ChipReading(device: 0, kind: 'cuda', powerW: 312.5),
        ChipReading(device: 1, kind: 'cuda', powerW: 300),
      ]);
    final rows = await readRunRows((await spool.finish({}))!);

    // Every row but the counts, which only matter at their maximum (the
    // file keeps a request's, not each chunk's).
    Object key(PerfEvent e) => (
      e.timestampNs,
      e.requestId,
      e.seq,
      e.answerChars,
      e.reasoningChars,
      e.requestTimestampNs,
      e.error,
      e.ends,
    );
    final recorded = PerfCsvParser().add(csv);
    expect(rows.events.map(key), recorded.map(key));
    int most(Iterable<PerfEvent> es, int Function(PerfEvent) f) =>
        es.map(f).reduce((a, b) => a > b ? a : b);
    for (final id in ['c0-0', 'c1-0']) {
      final mine = rows.events.where((e) => e.requestId == id);
      final theirs = recorded.where((e) => e.requestId == id);
      expect(
        most(mine, (e) => e.inputTokens),
        most(theirs, (e) => e.inputTokens),
      );
      expect(
        most(mine, (e) => e.outputTokens),
        most(theirs, (e) => e.outputTokens),
      );
    }
    expect(
      [for (final (ts, c) in rows.chips) (ts, c.device, c.powerW)],
      [(1000250000, 0, 312.5), (1000250000, 1, 300.0)],
    );
  });

  test('export rewrites the meta, keeps the data', () async {
    final spool = await RunSpool.create('p-2');
    spool.addEvents(csv);
    final path = await spool.finish({'schema_version': 1});
    final out = '${tmp.path}/exported/llmd it\'s.jsonl.gz';
    final meta = {
      'label': "llmd · it's",
      'server': {'commit': 'a1b2c3d'},
    };
    await exportRun(runFile: path!, meta: meta, out: out);

    // The times' origin stays the file's, whatever the meta says.
    expect(await readRunMeta(out), {
      'schema_version': 1,
      't0_unix_us': 1000000,
      ...meta,
    });
    expect(lines(out).skip(1), lines(path).skip(1));
    expect(File('$out.tmp').existsSync(), isFalse);
  });

  test('a run that streamed nothing leaves no file', () async {
    final spool = await RunSpool.create('p-3');
    expect(await spool.finish({}), isNull);
    expect(runFileExists('p-3'), isFalse);
  });

  test('zml-smi responses become chip readings', () {
    final readings = ChipReading.parse(
      jsonDecode('''
      {"devices": [
         {"cuda": {"name": "NVIDIA GeForce RTX 4090", "driver_version": "580.82",
                   "util_percent": 97, "power_mw": 312500, "power_limit_mw": 450000,
                   "temperature": 71, "mem_used_bytes": 20000000000,
                   "mem_total_bytes": 25757220864, "clock_graphics_mhz": 2520,
                   "clock_mem_mhz": 10501, "pcie_tx_kbps": 1200, "pcie_rx_kbps": 3400}},
         {"tpu": {"name": "v5e", "util_percent": 40}}
       ],
       "processes": []}
      '''),
    );
    expect(readings, hasLength(2));
    final gpu = readings.first;
    expect(gpu.kind, 'cuda');
    expect(gpu.powerW, 312.5);
    expect(gpu.powerLimitW, 450);
    expect(gpu.temperatureC, 71);
    expect(gpu.toMeta(), {
      'device': 0,
      'kind': 'cuda',
      'name': 'NVIDIA GeForce RTX 4090',
      'driver_version': '580.82',
    });
    expect(readings[1].device, 1);
    expect(readings[1].powerW, isNull);
    expect(ChipReading.parse('nonsense'), isEmpty);
  });
}
