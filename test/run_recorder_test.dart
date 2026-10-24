import 'dart:convert';
import 'dart:io';

import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:dart_duckdb/open.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/perf/domain/run_recorder.dart';

/// The DuckDB library the plugin downloads (flutter test runs without the
/// app, so the plugin's linked copy isn't there).
final _libduckdb =
    '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
    'dart_duckdb-1.4.4/macos/Libraries/release/libduckdb.dylib';

void main() {
  final skip = !File(_libduckdb).existsSync()
      ? 'libduckdb not downloaded yet (run a macOS build once)'
      : null;

  late Directory tmp;
  setUpAll(() => open.overrideFor(OperatingSystem.macOS, _libduckdb));
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('run_recorder_test');
    debugRunsDir = tmp.path;
  });
  tearDown(() {
    debugRunsDir = null;
    tmp.deleteSync(recursive: true);
  });

  Future<List<List<Object?>>> query(String sql) async {
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

  // The benchmarker's CSV, awkward tokens included: commas, quotes,
  // newlines, non-ASCII, an empty role chunk, an error row.
  const csv =
      'timestamp,request_id,seq,token,request_timestamp,inputs_tokens,'
      'outputs_tokens,concurrency,server,session_id,error\n'
      '1000000200,c0-0,0,,1000000000,0,1,16,zml,s,\n'
      '1000000300,c0-0,1,"Hello, ""world""",1000000000,0,2,16,zml,s,\n'
      '1000000400,c0-0,2,"two\nlines",1000000000,0,3,16,zml,s,\n'
      '1000000500,c0-0,3,café,1000000000,42,4,16,zml,s,\n'
      '1000000600,c1-0,0,,1000000100,0,0,16,zml,s,connection reset\n';

  test('a run becomes one Parquet file: events, chips, meta', () async {
    final spool = await RunSpool.create('p-1');
    // Chunks are cut anywhere, mid-row included.
    spool
      ..addEvents(csv.substring(0, 150))
      ..addEvents(csv.substring(150))
      ..addChipSample(1000000250, const [
        ChipReading(
          device: 0,
          kind: 'cuda',
          name: 'NVIDIA "RTX" 4090',
          utilPercent: 97,
          powerW: 312.5,
          memUsedBytes: 20000000000,
        ),
      ]);
    final path = await spool.finish({'schema_version': 1, 'label': 'é ’ x'});

    expect(path, runFilePath('p-1'));
    expect(File(path!).existsSync(), isTrue);
    expect(Directory('${tmp.path}/.spool/p-1').existsSync(), isFalse);

    final q = "read_parquet('$path')";
    expect(
      await query('SELECT source, count(*) FROM $q GROUP BY 1 ORDER BY 1'),
      [
        ['chip', 1],
        ['event', 5],
      ],
    );
    expect(
      await query(
        "SELECT request_id, seq, token_chars, output_tokens, input_tokens, error "
        "FROM $q WHERE source = 'event' ORDER BY ts_ns",
      ),
      [
        ['c0-0', 0, 0, 1, 0, ''],
        ['c0-0', 1, 14, 2, 0, ''], // Hello, "world"
        ['c0-0', 2, 9, 3, 0, ''], // two\nlines
        ['c0-0', 3, 4, 4, 42, ''], // café
        ['c1-0', 0, 0, 0, 0, 'connection reset'],
      ],
    );
    expect(
      await query(
        "SELECT ts_ns, device, kind, name, util_percent, power_w, "
        "mem_used_bytes, temperature_c FROM $q WHERE source = 'chip'",
      ),
      [
        [
          1000000250,
          0,
          'cuda',
          'NVIDIA "RTX" 4090',
          97,
          312.5,
          20000000000,
          null,
        ],
      ],
    );
    // No token text in the file.
    expect(
      (await query("SELECT * FROM $q LIMIT 0")).isEmpty &&
          !(await query(
            "SELECT column_name FROM (DESCRIBE SELECT * FROM $q)",
          )).any((r) => r.first == 'token'),
      isTrue,
    );
    expect(await readRunMeta(path), {'schema_version': 1, 'label': 'é ’ x'});
  }, skip: skip);

  test('export rewrites the meta, keeps the data', () async {
    final spool = await RunSpool.create('p-2');
    spool.addEvents(csv);
    final path = await spool.finish({'schema_version': 1});
    final out = '${tmp.path}/exported/llmd it\'s.zmlrun.parquet';
    final meta = {
      'schema_version': 1,
      'label': "llmd · it's",
      'server': {'commit': 'a1b2c3d'},
    };
    await exportRun(runFile: path!, meta: meta, out: out);

    expect(await readRunMeta(out), meta);
    final rows =
        "SELECT * EXCLUDE (source) FROM read_parquet('%') ORDER BY ts_ns";
    expect(
      await query(rows.replaceAll('%', out.replaceAll("'", "''"))),
      await query(rows.replaceAll('%', path)),
    );
    expect(File('$out.tmp').existsSync(), isFalse);
  }, skip: skip);

  test('a run that streamed nothing leaves no file', () async {
    final spool = await RunSpool.create('p-3');
    expect(await spool.finish({}), isNull);
    expect(runFileExists('p-3'), isFalse);
  }, skip: skip);

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
