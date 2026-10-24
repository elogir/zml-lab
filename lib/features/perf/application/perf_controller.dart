import 'dart:async';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_log.dart';
import '../../../models/perf_report.dart';
import '../../../repositories/perf_report_repository.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/bench_lib.dart';
import '../domain/bench_runner.dart';
import '../domain/csv_events.dart';
import '../domain/perf_stats.dart';
import '../domain/report_text.dart';
import '../domain/run_recorder.dart';
import '../domain/sharegpt.dart';

part 'perf_controller.g.dart';

enum PerfPhase {
  idle,

  /// Warming the server up, loading the dataset.
  preparing,
  running,

  /// Cancel requested — the benchmarker is cancelling its requests and
  /// flushing its CSV.
  stopping,
  done,
  failed;

  bool get isActive =>
      this == PerfPhase.preparing ||
      this == PerfPhase.running ||
      this == PerfPhase.stopping;
}

/// State of a job's perf benchmark tab.
class PerfRun {
  const PerfRun({
    this.phase = PerfPhase.idle,
    this.message,
    this.params = const PerfParams(),
    this.series = const [],
    this.events = 0,
    this.requests = 0,
    this.active = 0,
    this.errors = 0,
    this.liveTps = 0,
    this.elapsed = Duration.zero,
    this.report,
    this.saved = false,
    this.runFile,
    this.chips = false,
  });

  final PerfPhase phase;

  /// Live status line ('building benchmarker…', '94145 conversations', …).
  final String? message;
  final PerfParams params;
  final List<PerfSeriesPoint> series;
  final int events;
  final int requests;

  /// Requests that streamed an event in the last full sample bucket.
  final int active;
  final int errors;

  /// Events/second over the whole run so far (the tool's tokens_per_second).
  final double liveTps;
  final Duration elapsed;

  /// The finished run's report (also set for a cancelled partial run).
  final PerfReport? report;

  /// Whether [report] has been saved to the library already.
  final bool saved;

  /// The finished run's recording (`.zmlrun.parquet`), once written — what
  /// "Export run…" exports. Null while running, or if recording failed.
  final String? runFile;

  /// Whether zml-smi chip metrics are being (or were) recorded.
  final bool chips;

  static const _unset = Object();

  PerfRun copyWith({
    PerfPhase? phase,
    Object? message = _unset,
    PerfParams? params,
    List<PerfSeriesPoint>? series,
    int? events,
    int? requests,
    int? active,
    int? errors,
    double? liveTps,
    Duration? elapsed,
    Object? report = _unset,
    bool? saved,
    Object? runFile = _unset,
    bool? chips,
  }) => PerfRun(
    phase: phase ?? this.phase,
    message: identical(message, _unset) ? this.message : message as String?,
    params: params ?? this.params,
    series: series ?? this.series,
    events: events ?? this.events,
    requests: requests ?? this.requests,
    active: active ?? this.active,
    errors: errors ?? this.errors,
    liveTps: liveTps ?? this.liveTps,
    elapsed: elapsed ?? this.elapsed,
    report: identical(report, _unset) ? this.report : report as PerfReport?,
    saved: saved ?? this.saved,
    runFile: identical(runFile, _unset) ? this.runFile : runFile as String?,
    chips: chips ?? this.chips,
  );
}

/// Runs the bundled Go benchmarker (native/zmlbench, over FFI — see
/// bench_lib.dart) against a job's endpoint and turns its CSV event stream
/// into live charts and a final report. The library does the load
/// generation; the app computes the statistics (PerfAccumulator).
@Riverpod(keepAlive: true)
class PerfController extends _$PerfController {
  PerfCsvParser? _parser;
  PerfAccumulator? _acc;
  BenchLibRun? _run;
  Timer? _ticker;
  DateTime? _runningSince;
  bool _cancelRequested = false;
  bool _seriesDirty = false;
  int _runSeq = 0;
  String? _lastLog;

  // Job context captured at start, for the report.
  String _jobName = '';
  String _jobCommand = '';
  String _machineName = '';
  String _endpoint = '';
  String _host = '';
  int _port = 0;
  String? _machine;
  String? _hardware;

  // The run's recording (run_recorder.dart): spooled while it streams,
  // written as its .zmlrun.parquet when it ends.
  String _runId = '';
  DateTime? _startedAt;
  RunSpool? _spool;
  Timer? _chipTimer;
  bool _chipBusy = false;
  String? _chipUrl;
  List<ChipReading> _chipsSeen = const [];
  String? _serverVersion;

  /// Runs saved as reports: their recordings stay when the run is cleared.
  final _savedRunIds = <String>{};

  /// How often zml-smi is sampled (it refreshes every 500 ms by default).
  static const chipIntervalMs = 500;

  @override
  PerfRun build(String jobId) {
    ref.onDispose(_teardown);
    // Params live in settings (the single source shared with the Settings
    // screen). Mirror later settings edits into the form while idle, so
    // changing a default there shows up here without disrupting a live run.
    // (The PerfParams equality guard keeps this from firing on our own edits.)
    ref.listen(settingsControllerProvider, (_, next) {
      if (!state.phase.isActive && next.perfParams != state.params) {
        state = state.copyWith(params: next.perfParams);
      }
    });
    return PerfRun(params: ref.read(settingsControllerProvider).perfParams);
  }

  void setParams(PerfParams params) {
    state = state.copyWith(params: params);
    // Persist on every edit so it survives leaving and returning to the tab
    // and stays in sync with the Settings screen (both edit this one blob).
    ref.read(settingsControllerProvider.notifier).setPerfParams(params);
  }

  /// Prefills the model name from the server's /v1/models when the form has
  /// none yet (vLLM requires the real name; llmd ignores it).
  Future<void> prefillModel({required String host, required int port}) async {
    if (state.params.model.isNotEmpty) return;
    final ids = await fetchModelIds(host: host, port: port);
    if (ids.isEmpty || state.params.model.isNotEmpty) return;
    setParams(state.params.copyWith(model: ids.first));
  }

  /// What a run needs and doesn't have — null when good to go.
  Future<String?> preflight() async =>
      libraryProblem() ?? await _datasetProblem();

  /// Why the benchmarker itself can't run (the dataset aside — the Perf tab
  /// offers to download that).
  String? libraryProblem() => benchLibProblem();

  Future<String?> _datasetProblem() =>
      datasetProblem(ref.read(settingsControllerProvider).perfDatasetPath);

  /// Runs the benchmark. [machine] and [hardware] describe the target when
  /// it's a saved machine (for the recording's meta.json).
  Future<void> start({
    required String host,
    required int port,
    required String jobName,
    required String jobCommand,
    required String machineName,
    String? machine,
    String? hardware,
  }) async {
    if (state.phase.isActive) return;
    // A new run replaces an unsaved one, recording included.
    final previous = state.report;
    if (previous != null && !_savedRunIds.contains(previous.id)) {
      unawaited(deleteRun(previous.id));
    }
    final seq = ++_runSeq;
    final params = state.params;
    _jobName = jobName;
    _jobCommand = jobCommand;
    _machineName = machineName;
    _endpoint = '$machineName:$port';
    _host = host;
    _port = port;
    _machine = machine;
    _hardware = hardware;
    _cancelRequested = false;
    _lastLog = null;
    _parser = PerfCsvParser();
    _acc = PerfAccumulator();
    _runId = 'p-${DateTime.now().microsecondsSinceEpoch}';
    _startedAt = DateTime.now().toUtc();
    _chipsSeen = const [];
    _chipUrl = null;
    _serverVersion = null;

    final settings = ref.read(settingsControllerProvider);
    state = state.copyWith(
      phase: PerfPhase.preparing,
      message: 'starting…',
      series: const [],
      events: 0,
      requests: 0,
      active: 0,
      errors: 0,
      liveTps: 0,
      elapsed: Duration.zero,
      report: null,
      saved: false,
      runFile: null,
      chips: false,
    );
    AppLog.write(
      'perf run start job=$jobName endpoint=$host:$port '
      'd=${params.durationSeconds}s c=${params.concurrency}',
    );

    try {
      final problem = await preflight();
      if (problem != null) throw Exception(problem);

      if (params.warmup) {
        state = state.copyWith(message: 'warming up the server…');
        await warmupRequest(host: host, port: port, model: params.model);
        if (seq != _runSeq) return;
      }

      await _startRecording(seq, settings.perfChipMetricsUrl);
      if (seq != _runSeq) return;

      state = state.copyWith(message: 'loading ShareGPT dataset…');
      final run = startBenchLib(
        _config(params, host, port, settings.perfDatasetPath),
        onCsv: (chunk) => _onCsv(seq, chunk),
        onLog: (line) => _onLog(seq, line),
      );
      _run = run;
      // One refresh per series bucket (the library flushes every 50 ms).
      _ticker = Timer.periodic(
        const Duration(milliseconds: PerfAccumulator.bucketMs),
        (_) => _tick(),
      );
      final summary = await run.done;
      if (seq != _runSeq) return;
      _finish(seq, summary);
    } catch (e) {
      if (seq != _runSeq) return;
      _stopTicker();
      _stopRecording(discard: true);
      final message = '$e'.replaceFirst('Exception: ', '');
      AppLog.write('perf run failed: $message');
      state = state.copyWith(phase: PerfPhase.failed, message: message);
    }
  }

  // The trailing slash on /v1/ matters: openai-go resolves the route
  // RFC 3986-relative against the base URL, so without it the /v1 segment
  // is dropped (llmd tolerates that via a root-level route; vLLM 404s).
  BenchLibConfig _config(
    PerfParams p,
    String host,
    int port,
    String datasetPath,
  ) => BenchLibConfig(
    url: 'http://$host:$port/v1/',
    inputFile: expandUserPath(datasetPath),
    model: p.model,
    concurrency: p.concurrency,
    durationSeconds: p.durationSeconds,
    maxCompletionTokens: p.maxCompletionTokens,
    mode: p.mode,
    sequenceType: p.sequenceType,
  );

  /// Opens the run's spool, and — when zml-smi answers at [chipUrl] — starts
  /// sampling it. Recording is best-effort: a run goes ahead without it.
  Future<void> _startRecording(int seq, String chipUrl) async {
    try {
      _spool = await RunSpool.create(_runId);
    } catch (e) {
      AppLog.write('perf recording unavailable: $e');
      _spool = null;
    }
    // vLLM says its version; others don't (it's then entered at export).
    unawaited(
      fetchServerVersion(host: _host, port: _port).then((v) {
        if (seq == _runSeq) _serverVersion = v;
      }),
    );
    final url = chipUrl.replaceAll('{host}', _host).trim();
    if (_spool == null || url.isEmpty) return;
    final first = await fetchChips(url);
    if (seq != _runSeq) return;
    if (first.isEmpty) {
      AppLog.write('perf: no zml-smi at $url — no chip metrics');
      return;
    }
    _chipUrl = url;
    _chipsSeen = first;
    _spool?.addChipSample(DateTime.now().microsecondsSinceEpoch * 1000, first);
    state = state.copyWith(chips: true);
    _chipTimer = Timer.periodic(const Duration(milliseconds: chipIntervalMs), (
      _,
    ) async {
      if (_chipBusy) return; // a slow answer: skip a beat, don't pile up
      _chipBusy = true;
      try {
        final readings = await fetchChips(url);
        if (seq != _runSeq || readings.isEmpty) return;
        // Stamped on arrival, on the same clock as the events.
        _spool?.addChipSample(
          DateTime.now().microsecondsSinceEpoch * 1000,
          readings,
        );
      } finally {
        _chipBusy = false;
      }
    });
  }

  /// Stops sampling chips; with [discard], drops the spool too.
  void _stopRecording({bool discard = false}) {
    _chipTimer?.cancel();
    _chipTimer = null;
    if (discard) {
      final spool = _spool;
      _spool = null;
      unawaited(spool?.discard());
    }
  }

  /// Writes the finished run's .zmlrun.parquet (DuckDB, off the UI isolate)
  /// and records where it is.
  Future<void> _writeRunFile(int seq, PerfReport report) async {
    final spool = _spool;
    _spool = null;
    if (spool == null) return;
    try {
      final path = await spool.finish(_autoMeta(report));
      if (seq != _runSeq || state.report?.id != report.id) {
        // Discarded (or another run started) while it was being written.
        if (path != null && !_savedRunIds.contains(report.id)) {
          await deleteRun(report.id);
        }
        return;
      }
      state = state.copyWith(runFile: path);
    } catch (e) {
      AppLog.write('perf recording failed: $e');
      // Said in the status bar, or the missing Export run… is a mystery.
      if (seq == _runSeq && state.report?.id == report.id) {
        state = state.copyWith(
          message: '${state.message ?? 'run complete'} — not recorded: $e',
        );
      }
    }
  }

  /// What the app knows about the run, for its meta.json — the rest (label,
  /// commit, quantization, notes, tags) comes from the export dialog.
  Map<String, Object?> _autoMeta(PerfReport report) {
    final p = report.params;
    final datasetPath = ref.read(settingsControllerProvider).perfDatasetPath;
    final client = clientInfo();
    return {
      'schema_version': 1,
      'run_id': report.id,
      'label': [
        report.server,
        if (p.model.isNotEmpty) p.model.split('/').last,
        'c=${p.concurrency}',
      ].join(' · '),
      'started_at': _startedAt?.toIso8601String(),
      'ended_at': DateTime.now().toUtc().toIso8601String(),
      'cancelled': report.cancelled,
      'app': {'benchmarker_api': 1},
      if (client.isNotEmpty) 'client': client,
      'target': {'url': 'http://$_host:$_port/v1/', 'machine': ?_machine},
      'server': {'kind': report.server, 'version': ?_serverVersion},
      'model': {if (p.model.isNotEmpty) 'name': p.model},
      'hardware': {
        if (_hardware?.isNotEmpty ?? false) 'description': _hardware,
        if (_chipsSeen.isNotEmpty)
          'chips': [for (final c in _chipsSeen) c.toMeta()],
      },
      'params': {
        'duration_s': p.durationSeconds,
        'concurrency': p.concurrency,
        'max_completion_tokens': p.maxCompletionTokens,
        'prompts': p.sequenceType,
        'turns': p.mode,
        'warmup': p.warmup,
      },
      'dataset': {
        'name': datasetPath.split('/').last,
        // The official file (same size) — hashing 673 MB per run isn't worth
        // it to tell.
        if (fileSize(datasetPath) == ShareGpt.bytes) 'sha256': ShareGpt.sha256,
      },
      'chip_metrics': _chipUrl == null
          ? null
          : {'url': _chipUrl, 'interval_ms': chipIntervalMs},
      'summary': {
        'requests': report.totalRequests,
        'tokens_per_second': report.tokensPerSecond,
        'requests_per_second': report.requestsPerSecond,
        'errors': report.errorCount,
      },
    };
  }

  void _onCsv(int seq, String chunk) {
    if (seq != _runSeq) return;
    _spool?.addEvents(chunk);
    final events = _parser?.add(chunk) ?? const [];
    if (events.isEmpty) return;
    _acc?.addAll(events);
    _seriesDirty = true;
    if (state.phase == PerfPhase.preparing) {
      // First events beat the "Starting workers" log line sometimes.
      _markRunning();
    }
  }

  void _onLog(int seq, String line) {
    if (seq != _runSeq) return;
    _lastLog = line;
    if (line.contains('Number of conversations:')) {
      final n = line.split(':').last.trim();
      state = state.copyWith(message: '$n conversations loaded');
    } else if (line.contains('Starting') && line.contains('workers')) {
      _markRunning();
    }
  }

  void _markRunning() {
    if (state.phase != PerfPhase.preparing) return;
    _runningSince = DateTime.now();
    state = state.copyWith(phase: PerfPhase.running, message: null);
  }

  void _tick() {
    final acc = _acc;
    if (acc == null || !state.phase.isActive) return;
    final since = _runningSince;
    // The chart leaves out the newest (partial) bucket so its tail doesn't
    // dip; ACTIVE reads it.
    final series = acc.series(includeLast: true);
    state = state.copyWith(
      elapsed: since == null ? Duration.zero : DateTime.now().difference(since),
      series: _seriesDirty && series.length > 1
          ? series.sublist(0, series.length - 1)
          : null,
      events: acc.eventCount,
      requests: acc.requestCount,
      active: series.lastOrNull?.active ?? 0,
      errors: acc.errorCount,
      liveTps: acc.liveTokensPerSecond,
    );
    _seriesDirty = false;
  }

  void _finish(int seq, BenchLibSummary summary) {
    _stopTicker();
    final acc = _acc;
    _run = null;
    if (summary.error != null) {
      AppLog.write('perf benchmarker: ${summary.error}');
    }
    if (acc == null || acc.eventCount == 0) {
      _stopRecording(discard: true);
      final reason = summary.error ?? _lastLog ?? 'the server sent nothing';
      AppLog.write('perf run produced no events ($reason)');
      state = state.copyWith(
        phase: PerfPhase.failed,
        message: 'no events — $reason',
      );
      return;
    }
    _stopRecording();
    final params = state.params;
    final report = PerfReport(
      // The recording is kept as runs/<id>.zmlrun.parquet.
      id: _runId,
      name: _jobName,
      jobName: _jobName,
      machineName: _machineName,
      endpoint: _endpoint,
      jobCommand: _jobCommand,
      // The parameters are on the report; there's no CLI to quote anymore.
      benchCommand: '',
      server: acc.server.isEmpty ? 'unknown' : acc.server,
      createdAt: DateTime.now(),
      params: params,
      totalSeconds: acc.totalSeconds,
      totalEvents: acc.eventCount,
      totalRequests: acc.requestCount,
      tokensPerSecond: acc.tokensPerSecond,
      requestsPerSecond: acc.requestsPerSecond,
      maxSeq: acc.maxSeq,
      errorCount: acc.errorCount,
      errorSample: acc.firstError,
      cancelled: _cancelRequested,
      stats: acc.statRows(),
      series: acc.series(includeLast: true),
      ttftHistogram: acc.ttftHistogram(),
      itlHistogram: acc.itlHistogram(),
    );
    AppLog.write(
      'perf run done: ${report.totalRequests} requests, '
      '${report.tokensPerSecond.toStringAsFixed(1)} tok/s, '
      '${report.errorCount} errors',
    );
    state = state.copyWith(
      phase: PerfPhase.done,
      message: _cancelRequested ? 'stopped early — partial run' : null,
      report: report,
      series: report.series,
      events: report.totalEvents,
      requests: report.totalRequests,
      errors: report.errorCount,
      liveTps: report.tokensPerSecond,
    );
    unawaited(_writeRunFile(seq, report));
  }

  /// Stops the benchmarker: in-flight requests are cancelled, the CSV
  /// flushed, and a partial report still lands. During
  /// the warm-up there's no run yet — it's abandoned instead: bumping the
  /// sequence makes every pending await in start() a no-op.
  void cancel() {
    final run = _run;
    if (run == null) {
      if (state.phase == PerfPhase.preparing) {
        _runSeq++;
        _stopRecording(discard: true);
        state = state.copyWith(phase: PerfPhase.idle, message: null);
      }
      return;
    }
    if (_cancelRequested) return;
    _cancelRequested = true;
    run.stop();
    state = state.copyWith(
      phase: PerfPhase.stopping,
      message: 'stopping — flushing events…',
    );
  }

  /// Text for the "Copy results" button: the report's tables.
  Future<String> copyText() async {
    final report = state.report;
    return report == null ? '' : perfReportTable(report);
  }

  /// Saves the finished run's report under [name].
  Future<void> saveReport(String name) async {
    final report = state.report;
    if (report == null) return;
    final toSave = report.copyWith(name: name);
    _savedRunIds.add(report.id);
    await ref.read(perfReportRepositoryProvider).save(toSave);
    if (state.report?.id == report.id) {
      state = state.copyWith(report: toSave, saved: true);
    }
  }

  /// Clears a finished/failed run back to the idle form. An unsaved run's
  /// recording goes with it (a saved report keeps its own).
  void discard() {
    if (state.phase.isActive) return;
    final report = state.report;
    if (report != null && !_savedRunIds.contains(report.id)) {
      unawaited(deleteRun(report.id));
    }
    state = state.copyWith(
      phase: PerfPhase.idle,
      message: null,
      report: null,
      series: const [],
      saved: false,
      runFile: null,
      chips: false,
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _teardown() {
    _runSeq++;
    _stopTicker();
    _stopRecording(discard: true);
    _run?.stop();
    _run = null;
  }
}
