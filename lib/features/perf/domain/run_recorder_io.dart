import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_duckdb/dart_duckdb.dart';

import 'run_recorder_types.dart';

export 'run_recorder_types.dart';

/// Where finished runs are kept (`<id>.zmlrun.parquet`), with in-progress
/// spools under `.spool/`.
String runsDir() =>
    debugRunsDir ??
    '${Platform.environment['HOME']}/Library/Application Support/ZML-Lab/runs';

/// Tests point [runsDir] at a temporary folder.
String? debugRunsDir;

String runFilePath(String runId) => '${runsDir()}/$runId.zmlrun.parquet';

bool runFileExists(String runId) => File(runFilePath(runId)).existsSync();

Future<void> deleteRun(String runId) async {
  final file = File(runFilePath(runId));
  if (file.existsSync()) await file.delete();
}

/// One sample from `zml-smi --api` at [url]; empty if it doesn't answer (in
/// time) or isn't zml-smi.
Future<List<ChipReading>> fetchChips(
  String url, {
  Duration timeout = const Duration(milliseconds: 800),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != 200) return const [];
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    return ChipReading.parse(jsonDecode(body));
  } catch (_) {
    return const [];
  } finally {
    client.close(force: true);
  }
}

/// A run being recorded: the benchmarker's CSV and zml-smi samples appended
/// to files as they come (cheap — nothing parsed or converted while the run
/// streams), turned into the run's Parquet file by [finish].
class RunSpool {
  RunSpool._(this.runId, this._dir, this._events, this._chips);

  static Future<RunSpool> create(String runId) async {
    final dir = Directory('${runsDir()}/.spool/$runId');
    await dir.create(recursive: true);
    final events = File('${dir.path}/events.csv').openWrite();
    final chips = File('${dir.path}/chips.csv').openWrite()
      ..write('${_chipColumns.keys.join(',')}\n');
    return RunSpool._(runId, dir, events, chips);
  }

  final String runId;
  final Directory _dir;
  final IOSink _events;
  final IOSink _chips;
  int _chipRows = 0;
  bool _closed = false;

  /// A chunk of the benchmarker's CSV, verbatim (header included).
  void addEvents(String csvChunk) {
    if (!_closed) _events.write(csvChunk);
  }

  void addChipSample(int tsNs, List<ChipReading> devices) {
    if (_closed) return;
    for (final d in devices) {
      _chips.write(
        [
          tsNs,
          d.device,
          _csvString(d.kind),
          _csvString(d.name),
          d.utilPercent,
          d.powerW,
          d.powerLimitW,
          d.temperatureC,
          d.memUsedBytes,
          d.memTotalBytes,
          d.clockGraphicsMhz,
          d.clockMemMhz,
          d.pcieTxKbps,
          d.pcieRxKbps,
        ].map((v) => v ?? '').join(','),
      );
      _chips.write('\n');
      _chipRows++;
    }
  }

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;
    await _events.close();
    await _chips.close();
  }

  /// Writes the run's Parquet file with [meta] in its footer, removes the
  /// spool, and returns the file's path — or null if the run streamed
  /// nothing.
  Future<String?> finish(Map<String, Object?> meta) async {
    await _close();
    final events = File('${_dir.path}/events.csv');
    try {
      if (!events.existsSync() || events.lengthSync() == 0) return null;
      final out = runFilePath(runId);
      await _copyToParquet(
        source: _runQuery(
          eventsCsv: events.path,
          reasoning: await _hasReasoningColumn(events),
          chipsCsv: _chipRows > 0 ? '${_dir.path}/chips.csv' : null,
        ),
        meta: meta,
        out: out,
      );
      return out;
    } finally {
      await discard();
    }
  }

  /// Drops the spool (a run abandoned before it produced anything).
  Future<void> discard() async {
    await _close();
    if (_dir.existsSync()) await _dir.delete(recursive: true);
  }
}

/// Writes [runFile]'s data again to [out] with [meta] as its `meta.json` —
/// the export, once the dialog has filled in what couldn't be detected.
Future<void> exportRun({
  required String runFile,
  required Map<String, Object?> meta,
  required String out,
}) => _copyToParquet(
  source: 'SELECT * FROM read_parquet(${_sqlString(runFile)})',
  meta: meta,
  out: out,
);

/// The run's `meta.json`, from its footer (null if it has none).
Future<Map<String, Object?>?> readRunMeta(String runFile) async {
  final rows = await _query(
    'SELECT decode(value) FROM parquet_kv_metadata(${_sqlString(runFile)}) '
    "WHERE decode(key) = 'zml.run'",
  );
  if (rows.isEmpty) return null;
  return (jsonDecode(rows.first.first! as String) as Map)
      .cast<String, Object?>();
}

/// Whether the benchmarker's CSV has the `reasoning` column (builds from
/// before it was added don't).
Future<bool> _hasReasoningColumn(File csv) async {
  final head = await csv.openRead(0, 1024).transform(utf8.decoder).join();
  return head.split('\n').first.trim().split(',').contains('reasoning');
}

// The benchmarker's CSV columns (tools/benchmark), typed; `reasoning` comes
// after them when the build has it.
const _eventColumns = {
  'timestamp': 'BIGINT',
  'request_id': 'VARCHAR',
  'seq': 'INTEGER',
  'token': 'VARCHAR',
  'request_timestamp': 'BIGINT',
  'inputs_tokens': 'INTEGER',
  'outputs_tokens': 'INTEGER',
  'concurrency': 'INTEGER',
  'server': 'VARCHAR',
  'session_id': 'VARCHAR',
  'error': 'VARCHAR',
};

// The chip spool's columns — as they land in the run file.
const _chipColumns = {
  'ts_ns': 'BIGINT',
  'device': 'INTEGER',
  'kind': 'VARCHAR',
  'name': 'VARCHAR',
  'util_percent': 'INTEGER',
  'power_w': 'DOUBLE',
  'power_limit_w': 'DOUBLE',
  'temperature_c': 'INTEGER',
  'mem_used_bytes': 'BIGINT',
  'mem_total_bytes': 'BIGINT',
  'clock_graphics_mhz': 'INTEGER',
  'clock_mem_mhz': 'INTEGER',
  'pcie_tx_kbps': 'INTEGER',
  'pcie_rx_kbps': 'INTEGER',
};

/// The run table (docs/perf-run-format.md): events with their text reduced
/// to its length, chip samples alongside.
String _runQuery({
  required String eventsCsv,
  required bool reasoning,
  String? chipsCsv,
}) {
  final columns = {..._eventColumns, if (reasoning) 'reasoning': 'VARCHAR'};
  final events =
      '''
SELECT 'event' AS source,
       "timestamp" AS ts_ns,
       request_id,
       seq,
       request_timestamp AS request_ts_ns,
       CAST(length(coalesce(token, '')) AS INTEGER) AS token_chars,
       CAST(${reasoning ? "length(coalesce(reasoning, ''))" : '0'} AS INTEGER)
         AS reasoning_chars,
       outputs_tokens AS output_tokens,
       inputs_tokens AS input_tokens,
       coalesce(error, '') AS error
FROM read_csv(${_sqlString(eventsCsv)}, header = true, quote = '"',
              escape = '"', parallel = false,
              columns = ${_columnsStruct(columns)})''';
  if (chipsCsv == null) return events;
  return '''
$events
UNION ALL BY NAME
SELECT 'chip' AS source, *
FROM read_csv(${_sqlString(chipsCsv)}, header = true, quote = '"',
              escape = '"', columns = ${_columnsStruct(_chipColumns)})''';
}

Future<void> _copyToParquet({
  required String source,
  required Map<String, Object?> meta,
  required String out,
}) async {
  await File(out).parent.create(recursive: true);
  // Written next to the target and moved into place, so a failure never
  // leaves half a file where the run (or an export) should be.
  final tmp = '$out.tmp';
  await _execute(
    'COPY ($source) TO ${_sqlString(tmp)} '
    '(FORMAT parquet, COMPRESSION zstd, '
    "KV_METADATA {'zml.run': ${_sqlString(jsonEncode(meta))}})",
  );
  await File(tmp).rename(out);
}

String _sqlString(String s) => "'${s.replaceAll("'", "''")}'";

String _columnsStruct(Map<String, String> columns) =>
    '{${columns.entries.map((e) => '${_sqlString(e.key)}: ${_sqlString(e.value)}').join(', ')}}';

String _csvString(String? s) => s == null ? '' : '"${s.replaceAll('"', '""')}"';

// One in-memory DuckDB for the app, opened on first use; its connection runs
// queries on a background isolate.
Future<Connection>? _connection;

Future<Connection> _connect() => _connection ??= () async {
  final db = await duckdb.open(':memory:');
  return duckdb.connect(db);
}();

Future<void> _execute(String sql) async => (await _connect()).execute(sql);

Future<List<List<Object?>>> _query(String sql) async {
  final result = await (await _connect()).query(sql);
  return [for (final row in result.fetchAll()) row.toList()];
}
