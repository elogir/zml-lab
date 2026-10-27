import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'csv_events.dart';
import 'run_recorder_types.dart';

export 'run_recorder_types.dart';

/// Where finished runs are kept (`<id>.jsonl.gz`), with in-progress
/// spools under `.spool/`.
String runsDir() =>
    debugRunsDir ??
    '${Platform.environment['HOME']}/Library/Application Support/ZML-Lab/runs';

/// Tests point [runsDir] at a temporary folder.
String? debugRunsDir;

String runFilePath(String runId) => '${runsDir()}/$runId$runFileExtension';

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

/// A run being recorded: the benchmarker's CSV appended to a file as it
/// comes (cheap — nothing parsed while the run streams) and zml-smi samples
/// kept, turned into the run's file by [finish].
class RunSpool {
  RunSpool._(this.runId, this._dir, this._events);

  static Future<RunSpool> create(String runId) async {
    final dir = Directory('${runsDir()}/.spool/$runId');
    await dir.create(recursive: true);
    final events = File('${dir.path}/events.csv').openWrite();
    return RunSpool._(runId, dir, events);
  }

  final String runId;
  final Directory _dir;
  final IOSink _events;
  final List<(int, ChipReading)> _chips = [];
  bool _closed = false;

  /// A chunk of the benchmarker's CSV, verbatim (header included).
  void addEvents(String csvChunk) {
    if (!_closed) _events.write(csvChunk);
  }

  void addChipSample(int tsNs, List<ChipReading> devices) {
    if (_closed) return;
    for (final d in devices) {
      _chips.add((tsNs, d));
    }
  }

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;
    await _events.close();
  }

  /// Writes the run's file with [meta] as its meta line, removes the spool,
  /// and returns the file's path — or null if the run streamed nothing.
  Future<String?> finish(Map<String, Object?> meta) async {
    await _close();
    final events = File('${_dir.path}/events.csv');
    try {
      if (!events.existsSync() || events.lengthSync() == 0) return null;
      final out = runFilePath(runId);
      final csv = events.path;
      final chips = List.of(_chips);
      // Off the UI isolate: a long run's CSV is tens of megabytes.
      final written = await Isolate.run(() {
        final rows = PerfCsvParser().add(File(csv).readAsStringSync());
        if (rows.isEmpty) return false;
        _writeLines(out, runFileLines(meta, rows, chips));
        return true;
      });
      return written ? out : null;
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

/// The run file's lines (docs/perf-run-format.md) for [events] — the
/// benchmarker's rows, in the order they came — and the zml-smi [chips]:
/// the meta line, then a line per request and per chip sample, in time
/// order. Times are microseconds since the run's first request was sent.
List<String> runFileLines(
  Map<String, Object?> meta,
  List<PerfEvent> events,
  List<(int tsNs, ChipReading reading)> chips,
) {
  final t0 = events.map((e) => e.requestTimestampNs ~/ 1000).reduce(math.min);
  int us(int ns) => ns ~/ 1000 - t0;

  final requests = <String, _Request>{};
  for (final e in events) {
    final r = requests.putIfAbsent(
      e.requestId,
      () => _Request(e.requestId, us(e.requestTimestampNs)),
    );
    r.outputTokens = math.max(r.outputTokens, e.outputTokens);
    if (e.inputTokens > 0) r.inputTokens = e.inputTokens;
    // An error row isn't a chunk: it only ends the request.
    if (!e.isError) {
      r.chunkUs.add(us(e.timestampNs));
      r.answerChars.add(e.answerChars);
      r.reasoningChars.add(e.reasoningChars);
    } else {
      r.error = e.error;
    }
    if (e.ends) r.endUs = us(e.timestampNs);
  }

  // A request at its send time, a chip sample at its own; requests first
  // at the same time, otherwise as they came (a stable sort).
  final lines = <(int, int, Map<String, Object?>)>[
    for (final r in requests.values) (r.sentUs, 0, r.toLine()),
    for (final (ts, chip) in chips) (us(ts), 1, chip.toRunLine(us(ts))),
  ];
  mergeSort(
    lines,
    compare: (a, b) =>
        a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
  );
  return [
    jsonEncode(_metaLine(meta, t0)),
    for (final (_, _, line) in lines) jsonEncode(line),
  ];
}

class _Request {
  _Request(this.id, this.sentUs);

  final String id;
  final int sentUs;
  final chunkUs = <int>[];
  final answerChars = <int>[];
  final reasoningChars = <int>[];
  int? endUs;
  int inputTokens = 0;
  int outputTokens = 0;
  String? error;

  Map<String, Object?> toLine() {
    // `<conversation>-<turn>`, as the benchmarker names requests.
    final dash = id.lastIndexOf('-');
    final turn = dash < 0 ? null : int.tryParse(id.substring(dash + 1));
    return {
      'type': 'request',
      'id': id,
      'conversation': turn == null ? id : id.substring(0, dash),
      'turn': turn ?? 0,
      'sent_us': sentUs,
      'end_us': endUs,
      'input_tokens': inputTokens > 0 ? inputTokens : null,
      'output_tokens': outputTokens,
      'error': error,
      'chunk_us': chunkUs,
      'answer_chars': answerChars,
      'reasoning_chars': reasoningChars,
    };
  }
}

/// [meta] as the run file's first line: the recorder owns `type`,
/// `schema_version` and the times' origin `t0_unix_us`, which lead it.
Map<String, Object?> _metaLine(Map<String, Object?> meta, int t0Us) => {
  'type': 'meta',
  'schema_version': runSchemaVersion,
  't0_unix_us': t0Us,
  for (final MapEntry(:key, :value) in meta.entries)
    if (key != 'type' && key != 'schema_version' && key != 't0_unix_us')
      key: value,
};

/// Writes [runFile]'s data again to [out] with [meta] as its `meta.json` —
/// the export, once the dialog has filled in what couldn't be detected.
Future<void> exportRun({
  required String runFile,
  required Map<String, Object?> meta,
  required String out,
}) => Isolate.run(() {
  final lines = _readLines(runFile);
  final t0 = (_metaOf(lines.first)['t0_unix_us']! as num).toInt();
  lines[0] = jsonEncode(_metaLine(meta, t0));
  _writeLines(out, lines);
});

/// Puts [meta] in [runFile] as its `meta.json` — the details edited on a
/// saved run. The lines are written again to a new file moved over it.
Future<void> rewriteRunMeta(String runFile, Map<String, Object?> meta) =>
    exportRun(runFile: runFile, meta: meta, out: runFile);

/// The run's `meta.json`, its first line (`type` left out). Throws a
/// [FormatException] saying why if [runFile] isn't a run this app reads.
Future<Map<String, Object?>?> readRunMeta(String runFile) async {
  final String first;
  try {
    first = await File(runFile)
        .openRead()
        .transform(gzip.decoder)
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first;
  } on StateError {
    throw _notARunFile; // empty
  } on FormatException {
    throw _notARunFile;
  }
  return _metaOf(first)..remove('type');
}

/// [runFile]'s chunks and chip samples, rebuilt as the events and readings
/// a live run feeds its report, in time order. A conversation's chunks are
/// numbered (`seq`) across its turns, as the benchmarker numbers them.
Future<RunRows> readRunRows(String runFile) => Isolate.run(() {
  final lines = _readLines(runFile);
  final t0 = (_metaOf(lines.first)['t0_unix_us']! as num).toInt();
  int ns(Object? us) => (t0 + (us! as num).toInt()) * 1000;

  final requests = <Map<String, Object?>>[];
  final chips = <(int, ChipReading)>[];
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final o = (jsonDecode(line) as Map).cast<String, Object?>();
    switch (o['type']) {
      case 'request':
        requests.add(o);
      case 'chip':
        chips.add((ns(o['t_us']), ChipReading.fromRunLine(o)));
    }
  }

  String conversation(Map<String, Object?> r) =>
      (r['conversation'] ?? r['id']).toString();
  int turn(Map<String, Object?> r) => (r['turn'] as num?)?.toInt() ?? 0;
  final ordered = requests.indexed.toList()
    ..sort((a, b) {
      final c = conversation(a.$2).compareTo(conversation(b.$2));
      if (c != 0) return c;
      final t = turn(a.$2).compareTo(turn(b.$2));
      return t != 0 ? t : a.$1.compareTo(b.$1);
    });

  final events = <PerfEvent>[];
  final seqs = <String, int>{};
  for (final (_, r) in ordered) {
    final id = r['id'].toString();
    List<int> ints(String key) => [
      for (final v in r[key] as List? ?? const []) (v as num).toInt(),
    ];
    final chunkUs = ints('chunk_us');
    final answer = ints('answer_chars');
    final reasoning = ints('reasoning_chars');
    if (answer.length != chunkUs.length || reasoning.length != chunkUs.length) {
      throw FormatException('request $id: its chunk lists differ in length');
    }
    final sent = ns(r['sent_us']);
    final endUs = (r['end_us'] as num?)?.toInt();
    final error = r['error'] as String? ?? '';
    final inputTokens = (r['input_tokens'] as num?)?.toInt() ?? 0;
    final outputTokens = (r['output_tokens'] as num?)?.toInt() ?? 0;

    // The end is an event of its own unless it's the last chunk (the usage
    // chunk); the token counts go on the request's last event.
    final endIsLastChunk =
        error.isEmpty && endUs != null && chunkUs.lastOrNull == endUs;
    final extraEnd = error.isNotEmpty || (endUs != null && !endIsLastChunk);
    final conv = conversation(r);
    PerfEvent event(int us, {int a = 0, int rc = 0, required bool last}) {
      final seq = seqs[conv] ?? 0;
      seqs[conv] = seq + 1;
      final ends = last && (extraEnd || endIsLastChunk);
      return PerfEvent(
        timestampNs: (t0 + us) * 1000,
        requestId: id,
        seq: seq,
        answerChars: a,
        reasoningChars: rc,
        requestTimestampNs: sent,
        inputTokens: last ? inputTokens : 0,
        outputTokens: last ? outputTokens : 0,
        concurrency: 0,
        error: last && extraEnd ? error : '',
        ends: ends,
      );
    }

    for (var i = 0; i < chunkUs.length; i++) {
      events.add(
        event(
          chunkUs[i],
          a: answer[i],
          rc: reasoning[i],
          last: !extraEnd && i == chunkUs.length - 1,
        ),
      );
    }
    if (extraEnd) {
      final at = endUs ?? chunkUs.lastOrNull ?? (r['sent_us']! as num).toInt();
      events.add(event(at, last: true));
    }
  }
  mergeSort(events, compare: (a, b) => a.timestampNs.compareTo(b.timestampNs));
  mergeSort(chips, compare: (a, b) => a.$1.compareTo(b.$1));
  return RunRows(events: events, chips: chips);
});

/// Keeps [file] as run [runId]'s recording (an imported run), copied to its
/// place among the runs.
Future<void> keepRunFile(String file, String runId) async {
  final out = runFilePath(runId);
  if (File(file).absolute.path == File(out).absolute.path) return;
  await File(out).parent.create(recursive: true);
  // Copied next to it and moved into place, so a failure never leaves half
  // a file where the run should be.
  final tmp = '$out.tmp';
  await File(file).copy(tmp);
  await File(tmp).rename(out);
}

List<String> _readLines(String runFile) {
  final String text;
  try {
    text = utf8.decode(gzip.decode(File(runFile).readAsBytesSync()));
  } on FormatException {
    throw _notARunFile;
  }
  final lines = const LineSplitter().convert(text);
  if (lines.isEmpty) throw _notARunFile;
  return lines;
}

/// The meta line [line], or a [FormatException].
Map<String, Object?> _metaOf(String line) {
  final Object? o;
  try {
    o = jsonDecode(line);
  } on FormatException {
    throw _notARunFile;
  }
  // Only this version: any other file, whatever it is, isn't a run file.
  if (o is! Map ||
      o['type'] != 'meta' ||
      o['schema_version'] != runSchemaVersion) {
    throw _notARunFile;
  }
  if (o['t0_unix_us'] is! num) {
    throw const FormatException('its meta line has no t0_unix_us');
  }
  return o.cast<String, Object?>();
}

const _notARunFile = FormatException(
  'not a run file (gzipped JSON Lines starting with a meta line)',
);

/// Writes [lines] to [out] gzipped, next to it first and then moved into
/// place, so a failure never leaves half a file where the run should be.
void _writeLines(String out, List<String> lines) {
  File(out).parent.createSync(recursive: true);
  final tmp = '$out.tmp';
  File(tmp).writeAsBytesSync(gzip.encode(utf8.encode('${lines.join('\n')}\n')));
  File(tmp).renameSync(out);
}
