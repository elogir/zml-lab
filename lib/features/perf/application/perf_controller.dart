import 'dart:async';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_log.dart';
import '../../../models/perf_report.dart';
import '../../../repositories/perf_report_repository.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/bench_runner.dart';
import '../domain/csv_events.dart';
import '../domain/perf_stats.dart';
import '../domain/report_text.dart';

part 'perf_controller.g.dart';

enum PerfPhase {
  idle,

  /// Building the Go binary, warming the server up, loading the dataset.
  preparing,
  running,

  /// Cancel requested — the tool is draining workers and flushing its CSV.
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
  );
}

/// Runs the monorepo's Go benchmarker (tools/benchmark) against a job's
/// endpoint and turns its CSV event stream into live charts and a final
/// report. The tool does the load generation; the app only consumes its
/// native output (see PerfAccumulator for the report.sql parity).
@Riverpod(keepAlive: true)
class PerfController extends _$PerfController {
  PerfCsvParser? _parser;
  PerfAccumulator? _acc;
  BenchProcess? _process;
  Timer? _ticker;
  DateTime? _runningSince;
  bool _cancelRequested = false;
  bool _seriesDirty = false;
  int _runSeq = 0;
  String? _lastStderr;

  /// The finished run's raw event CSV (the tool's stdout), kept in memory so
  /// "Copy results" can pipe it through a duckdb command. Not persisted.
  final StringBuffer _rawCsv = StringBuffer();
  String _finishedCsv = '';

  // Job context captured at start, for the report.
  String _jobName = '';
  String _jobCommand = '';
  String _machineName = '';
  String _endpoint = '';
  String _host = '';
  int _port = 0;

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
  Future<String?> preflight() {
    final s = ref.read(settingsControllerProvider);
    return benchPreflight(
      toolDir: s.perfToolDir,
      datasetPath: s.perfDatasetPath,
    );
  }

  Future<void> start({
    required String host,
    required int port,
    required String jobName,
    required String jobCommand,
    required String machineName,
  }) async {
    if (state.phase.isActive) return;
    final seq = ++_runSeq;
    final params = state.params;
    _jobName = jobName;
    _jobCommand = jobCommand;
    _machineName = machineName;
    _endpoint = '$machineName:$port';
    _host = host;
    _port = port;
    _cancelRequested = false;
    _lastStderr = null;
    _parser = PerfCsvParser();
    _acc = PerfAccumulator();
    _rawCsv.clear();
    _finishedCsv = '';

    final settings = ref.read(settingsControllerProvider);
    state = state.copyWith(
      phase: PerfPhase.preparing,
      message: 'building benchmarker…',
      series: const [],
      events: 0,
      requests: 0,
      active: 0,
      errors: 0,
      liveTps: 0,
      elapsed: Duration.zero,
      report: null,
      saved: false,
    );
    AppLog.write('perf run start job=$jobName endpoint=$host:$port '
        'd=${params.durationSeconds}s c=${params.concurrency}');

    try {
      final problem = await benchPreflight(
        toolDir: settings.perfToolDir,
        datasetPath: settings.perfDatasetPath,
      );
      if (problem != null) throw Exception(problem);
      final bin = await buildBenchmarker(toolDir: settings.perfToolDir);
      if (seq != _runSeq) return;

      if (params.warmup) {
        state = state.copyWith(message: 'warming up the server…');
        await warmupRequest(host: host, port: port, model: params.model);
        if (seq != _runSeq) return;
      }

      state = state.copyWith(message: 'loading ShareGPT dataset…');
      final process = await startBenchmarker(
        binPath: bin,
        toolDir: settings.perfToolDir,
        args: _args(params, host, port, settings.perfDatasetPath),
        onCsv: (chunk) => _onCsv(seq, chunk),
        onStderr: (line) => _onStderr(seq, line),
      );
      if (seq != _runSeq) {
        process.kill();
        return;
      }
      _process = process;
      _ticker = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _tick(),
      );
      final code = await process.exited;
      if (seq != _runSeq) return;
      _finish(code);
    } catch (e) {
      if (seq != _runSeq) return;
      _stopTicker();
      final message = '$e'.replaceFirst('Exception: ', '');
      AppLog.write('perf run failed: $message');
      state = state.copyWith(phase: PerfPhase.failed, message: message);
    }
  }

  // The trailing slash on /v1/ matters: openai-go resolves the route
  // RFC 3986-relative against the base URL, so without it the /v1 segment
  // is dropped (llmd tolerates that via a root-level route; vLLM 404s).
  List<String> _args(
    PerfParams p,
    String host,
    int port,
    String datasetPath,
  ) => [
    '-u', 'http://$host:$port/v1/',
    '-d', '${p.durationSeconds}',
    '--concurrency', '${p.concurrency}',
    '--sequence_type', p.sequenceType,
    '--mode', p.mode,
    if (p.maxCompletionTokens != null)
      ...['--max-completion-tokens', '${p.maxCompletionTokens}'],
    if (p.model.isNotEmpty) ...['-m', p.model],
    '-i', expandUserPath(datasetPath),
  ];

  /// The invocation in the guide's `go run` form — stored on the report so
  /// results can be quoted with the exact command line.
  String _benchCommand(PerfParams p, String host, int port) => [
    'go run benchmark.go',
    '-u http://$host:$port/v1/',
    '-d ${p.durationSeconds}',
    '--concurrency ${p.concurrency}',
    '--sequence_type ${p.sequenceType}',
    '--mode ${p.mode}',
    if (p.maxCompletionTokens != null)
      '--max-completion-tokens ${p.maxCompletionTokens}',
    if (p.model.isNotEmpty) '-m ${p.model}',
  ].join(' ');

  void _onCsv(int seq, String chunk) {
    if (seq != _runSeq) return;
    _rawCsv.write(chunk); // kept verbatim for the duckdb copy
    final events = _parser?.add(chunk) ?? const [];
    if (events.isEmpty) return;
    _acc?.addAll(events);
    _seriesDirty = true;
    if (state.phase == PerfPhase.preparing) {
      // First events beat the "Starting workers" stderr line sometimes.
      _markRunning();
    }
  }

  void _onStderr(int seq, String line) {
    if (seq != _runSeq) return;
    _lastStderr = line;
    if (line.contains('Number of conversations:')) {
      final n = line.split(':').last.trim();
      state = state.copyWith(message: '$n conversations loaded');
    } else if (line.contains('Starting') && line.contains('workers')) {
      _markRunning();
    } else if (line.contains('Error reading file') ||
        line.contains('Error unmarshalling file')) {
      // The tool exits 0 on these — surface them as the failure reason.
      _lastStderr = 'benchmarker: ${line.replaceFirst(RegExp(r'^[\d/: ]+'), '')}';
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
    state = state.copyWith(
      elapsed: since == null ? Duration.zero : DateTime.now().difference(since),
      series: _seriesDirty ? acc.series(includeLast: false) : null,
      events: acc.eventCount,
      requests: acc.requestCount,
      active: acc.series(includeLast: true).lastOrNull?.active ?? 0,
      errors: acc.errorCount,
      liveTps: acc.liveTokensPerSecond,
    );
    _seriesDirty = false;
  }

  void _finish(int exitCode) {
    _stopTicker();
    final acc = _acc;
    _process = null;
    _finishedCsv = _rawCsv.toString();
    if (acc == null || acc.eventCount == 0) {
      final reason = _lastStderr ?? 'exit code $exitCode';
      AppLog.write('perf run produced no events ($reason)');
      state = state.copyWith(
        phase: PerfPhase.failed,
        message: 'no events — $reason',
      );
      return;
    }
    final params = state.params;
    final report = PerfReport(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}',
      name: _jobName,
      jobName: _jobName,
      machineName: _machineName,
      endpoint: _endpoint,
      jobCommand: _jobCommand,
      benchCommand: _benchCommand(params, _host, _port),
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
  }

  /// First press: SIGINT — the tool drains and flushes, and a partial report
  /// still lands. Second press: SIGKILL. During the preparing phase (go
  /// build / warmup) there's no process yet — the run is abandoned instead:
  /// bumping the sequence makes every pending await in start() a no-op.
  void cancel() {
    final process = _process;
    if (process == null) {
      if (state.phase == PerfPhase.preparing) {
        _runSeq++;
        state = state.copyWith(phase: PerfPhase.idle, message: null);
      }
      return;
    }
    if (_cancelRequested) {
      process.kill();
      return;
    }
    _cancelRequested = true;
    process.interrupt();
    state = state.copyWith(
      phase: PerfPhase.stopping,
      message: 'stopping — flushing events…',
    );
  }

  /// Text for the "Copy results" button. When a duckdb command is configured
  /// (Settings) it pipes the run's raw event CSV through it — the real CLI
  /// pipeline — and returns its output; otherwise (or if it fails, or the raw
  /// CSV is gone) it returns the app's own render of the report.
  Future<String> copyText() async {
    final report = state.report;
    if (report == null) return '';
    final fallback = perfReportTable(report);
    final command = ref.read(settingsControllerProvider).perfDuckdbCommand.trim();
    if (command.isEmpty || _finishedCsv.isEmpty) return fallback;
    final out = await runDuckdb(
      command: command,
      toolDir: ref.read(settingsControllerProvider).perfToolDir,
      csv: _finishedCsv,
    );
    return (out != null && out.trim().isNotEmpty) ? out : fallback;
  }

  /// Saves the finished run's report under [name].
  Future<void> saveReport(String name) async {
    final report = state.report;
    if (report == null) return;
    final toSave = report.copyWith(name: name);
    await ref.read(perfReportRepositoryProvider).save(toSave);
    if (state.report?.id == report.id) {
      state = state.copyWith(report: toSave, saved: true);
    }
  }

  /// Clears a finished/failed run back to the idle form.
  void discard() {
    if (state.phase.isActive) return;
    state = state.copyWith(
      phase: PerfPhase.idle,
      message: null,
      report: null,
      series: const [],
      saved: false,
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _teardown() {
    _runSeq++;
    _stopTicker();
    _process?.kill();
    _process = null;
  }
}
