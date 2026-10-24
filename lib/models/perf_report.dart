/// Models for the perf benchmark — runs of the bundled load generator
/// (native/zmlbench) against an endpoint: the statistics (as the run format
/// defines them, docs/perf-run-format.md), the chips zml-smi reported, plus
/// the time series the app samples live for the charts.
library;

/// One row of the statistics table: a metric summarized over the run.
/// Matches a row of report.sql's output (avg/min/max + percentiles).
class PerfStatRow {
  const PerfStatRow({
    required this.label,
    required this.unit,
    required this.avg,
    required this.min,
    required this.max,
    required this.p50,
    required this.p75,
    required this.p90,
    required this.p95,
    required this.p99,
    required this.p999,
  });

  final String label;

  /// Display unit — 'ms' for the latency rows, 'tok' for the length rows.
  final String unit;
  final double avg;
  final double min;
  final double max;
  final double p50;
  final double p75;
  final double p90;
  final double p95;
  final double p99;
  final double p999;

  /// The percentile columns in table order (after avg/min/max).
  List<double> get percentiles => [p50, p75, p90, p95, p99, p999];

  Map<String, dynamic> toMap() => {
    'l': label,
    'u': unit,
    'a': avg,
    'mn': min,
    'mx': max,
    'p50': p50,
    'p75': p75,
    'p90': p90,
    'p95': p95,
    'p99': p99,
    'p999': p999,
  };

  factory PerfStatRow.fromMap(Map<String, dynamic> m) {
    double d(String k) => (m[k] as num?)?.toDouble() ?? 0;
    return PerfStatRow(
      label: m['l'] as String? ?? '',
      unit: m['u'] as String? ?? '',
      avg: d('a'),
      min: d('mn'),
      max: d('mx'),
      p50: d('p50'),
      p75: d('p75'),
      p90: d('p90'),
      p95: d('p95'),
      p99: d('p99'),
      p999: d('p999'),
    );
  }
}

/// One point of the live time series, sampled while the benchmarker streams:
/// at [elapsedMs] into the run the server was producing [tps] tokens/second
/// (events per bucket), with [active] requests streaming and [requests]
/// distinct requests seen so far.
class PerfSeriesPoint {
  const PerfSeriesPoint({
    required this.elapsedMs,
    required this.tps,
    required this.active,
    required this.requests,
  });

  final int elapsedMs;
  final double tps;
  final int active;
  final int requests;

  Map<String, dynamic> toMap() =>
      {'t': elapsedMs, 'r': tps, 'a': active, 'n': requests};

  factory PerfSeriesPoint.fromMap(Map<String, dynamic> m) => PerfSeriesPoint(
    elapsedMs: (m['t'] as num?)?.toInt() ?? 0,
    tps: (m['r'] as num?)?.toDouble() ?? 0,
    active: (m['a'] as num?)?.toInt() ?? 0,
    requests: (m['n'] as num?)?.toInt() ?? 0,
  );
}

/// A pre-bucketed latency histogram (both distributions are binned before
/// persisting so a report stays a few KB no matter how big the run was).
/// The first bin starts at [binStartMs]; every bin is [binWidthMs] wide.
class PerfHistogram {
  const PerfHistogram({
    required this.binWidthMs,
    required this.binStartMs,
    required this.counts,
  });

  final double binWidthMs;
  final double binStartMs;
  final List<int> counts;

  bool get isEmpty => counts.isEmpty;

  Map<String, dynamic> toMap() =>
      {'w': binWidthMs, 's': binStartMs, 'c': counts};

  factory PerfHistogram.fromMap(Map<String, dynamic> m) => PerfHistogram(
    binWidthMs: (m['w'] as num?)?.toDouble() ?? 1,
    binStartMs: (m['s'] as num?)?.toDouble() ?? 0,
    counts: [for (final c in (m['c'] as List? ?? const [])) (c as num).toInt()],
  );
}

/// One accelerator over a run, from its zml-smi samples. Every reading is
/// optional: devices report different subsets.
class PerfChipStat {
  const PerfChipStat({
    required this.device,
    required this.kind,
    this.name,
    required this.samples,
    this.utilAvg,
    this.utilMax,
    this.powerAvgW,
    this.powerMaxW,
    this.temperatureMaxC,
    this.memPeakBytes,
    this.memTotalBytes,
    this.energyJ,
  });

  /// Index in zml-smi's device list.
  final int device;

  /// `cuda`, `rocm`, `oneapi`, `neuron` or `tpu`.
  final String kind;
  final String? name;
  final int samples;
  final double? utilAvg;
  final int? utilMax;
  final double? powerAvgW;
  final double? powerMaxW;
  final int? temperatureMaxC;
  final int? memPeakBytes;
  final int? memTotalBytes;

  /// Power integrated over the run, in joules.
  final double? energyJ;

  Map<String, dynamic> toMap() => {
    'd': device,
    'k': kind,
    'n': ?name,
    's': samples,
    'ua': ?utilAvg,
    'um': ?utilMax,
    'pa': ?powerAvgW,
    'pm': ?powerMaxW,
    'tm': ?temperatureMaxC,
    'mp': ?memPeakBytes,
    'mt': ?memTotalBytes,
    'e': ?energyJ,
  };

  factory PerfChipStat.fromMap(Map<String, dynamic> m) => PerfChipStat(
    device: (m['d'] as num?)?.toInt() ?? 0,
    kind: m['k'] as String? ?? '',
    name: m['n'] as String?,
    samples: (m['s'] as num?)?.toInt() ?? 0,
    utilAvg: (m['ua'] as num?)?.toDouble(),
    utilMax: (m['um'] as num?)?.toInt(),
    powerAvgW: (m['pa'] as num?)?.toDouble(),
    powerMaxW: (m['pm'] as num?)?.toDouble(),
    temperatureMaxC: (m['tm'] as num?)?.toInt(),
    memPeakBytes: (m['mp'] as num?)?.toInt(),
    memTotalBytes: (m['mt'] as num?)?.toInt(),
    energyJ: (m['e'] as num?)?.toDouble(),
  );
}

/// The parameters a run was launched with — everything needed to reproduce
/// the benchmarker invocation (and to prefill the next run's form).
class PerfParams {
  const PerfParams({
    this.durationSeconds = 30,
    this.concurrency = 16,
    this.sequenceType = 'long',
    this.mode = 'all',
    this.maxCompletionTokens,
    this.ignoreEos = false,
    this.model = '',
    this.warmup = true,
  });

  final int durationSeconds;
  final int concurrency;

  /// 'long' | 'short' — whether prompts are sent whole or capped at 512 chars.
  final String sequenceType;

  /// 'first' | 'all' — only each conversation's first prompt, or every turn.
  final String mode;

  /// Null = no cap: the server stops at EOS (or its max sequence length).
  /// Set to cap each request's output.
  final int? maxCompletionTokens;

  /// Generate past EOS up to the token cap: every reply is the same length,
  /// so runs compare like for like (`ignore_eos`, llmd/vLLM/SGLang).
  final bool ignoreEos;

  /// Model name sent in requests (vLLM requires the real one; llmd ignores it).
  final String model;

  /// Send one small chat request and wait for it before starting the load.
  final bool warmup;

  static const _unset = Object();

  PerfParams copyWith({
    int? durationSeconds,
    int? concurrency,
    String? sequenceType,
    String? mode,
    Object? maxCompletionTokens = _unset,
    bool? ignoreEos,
    String? model,
    bool? warmup,
  }) => PerfParams(
    durationSeconds: durationSeconds ?? this.durationSeconds,
    concurrency: concurrency ?? this.concurrency,
    sequenceType: sequenceType ?? this.sequenceType,
    mode: mode ?? this.mode,
    maxCompletionTokens: identical(maxCompletionTokens, _unset)
        ? this.maxCompletionTokens
        : maxCompletionTokens as int?,
    ignoreEos: ignoreEos ?? this.ignoreEos,
    model: model ?? this.model,
    warmup: warmup ?? this.warmup,
  );

  Map<String, dynamic> toMap() => {
    'd': durationSeconds,
    'c': concurrency,
    'st': sequenceType,
    'm': mode,
    if (maxCompletionTokens != null) 'mt': maxCompletionTokens,
    if (ignoreEos) 'ie': true,
    'model': model,
    'w': warmup,
  };

  factory PerfParams.fromMap(Map<String, dynamic> m) => PerfParams(
    durationSeconds: (m['d'] as num?)?.toInt() ?? 30,
    concurrency: (m['c'] as num?)?.toInt() ?? 16,
    sequenceType: m['st'] as String? ?? 'long',
    mode: m['m'] as String? ?? 'all',
    maxCompletionTokens: (m['mt'] as num?)?.toInt(),
    ignoreEos: m['ie'] as bool? ?? false,
    model: m['model'] as String? ?? '',
    warmup: m['w'] as bool? ?? true,
  );

  @override
  bool operator ==(Object other) =>
      other is PerfParams &&
      other.durationSeconds == durationSeconds &&
      other.concurrency == concurrency &&
      other.sequenceType == sequenceType &&
      other.mode == mode &&
      other.maxCompletionTokens == maxCompletionTokens &&
      other.ignoreEos == ignoreEos &&
      other.model == model &&
      other.warmup == warmup;

  @override
  int get hashCode => Object.hash(
    durationSeconds,
    concurrency,
    sequenceType,
    mode,
    maxCompletionTokens,
    ignoreEos,
    model,
    warmup,
  );
}

/// A completed perf benchmark run: the tool's statistics plus everything
/// needed to display and reproduce it.
class PerfReport {
  const PerfReport({
    required this.id,
    required this.name,
    required this.jobName,
    required this.machineName,
    required this.endpoint,
    required this.jobCommand,
    required this.benchCommand,
    required this.server,
    required this.createdAt,
    required this.params,
    required this.totalSeconds,
    required this.totalEvents,
    required this.totalRequests,
    required this.tokensPerSecond,
    required this.requestsPerSecond,
    this.maxSeq = 0,
    required this.errorCount,
    this.errorSample,
    this.cancelled = false,
    required this.stats,
    required this.series,
    required this.ttftHistogram,
    required this.itlHistogram,
    this.chips = const [],
    this.joulesPerToken,
  });

  final String id;
  final String name;
  final String jobName;
  final String machineName;

  /// `machine:port`, for display.
  final String endpoint;

  /// The job's launch command (llmd / vLLM command line) — the guide asks for
  /// it whenever numbers are reported.
  final String jobCommand;

  /// The exact benchmarker command line this run used.
  final String benchCommand;

  /// Server type as detected by the tool ('zml', 'vllm', 'openai', 'unknown').
  final String server;
  final DateTime createdAt;
  final PerfParams params;

  /// Wall time between the first request and the last event, in seconds
  /// (report.sql's total_seconds).
  final double totalSeconds;

  /// Total events written (report.sql's total_tokens).
  final int totalEvents;
  final int totalRequests;
  final double tokensPerSecond;
  final double requestsPerSecond;

  /// Highest event seq seen (report.sql's max_seq — the longest reply).
  final int maxSeq;
  final int errorCount;

  /// A representative error message from the errored requests, when any.
  final String? errorSample;

  /// True when the run was stopped early — the report covers a partial run.
  final bool cancelled;

  final List<PerfStatRow> stats;
  final List<PerfSeriesPoint> series;
  final PerfHistogram ttftHistogram;
  final PerfHistogram itlHistogram;

  /// The accelerators zml-smi reported during the run (empty when it
  /// wasn't answering).
  final List<PerfChipStat> chips;

  /// Energy per token, every chip together (null without power readings).
  final double? joulesPerToken;

  PerfReport copyWith({String? name}) => PerfReport(
    id: id,
    name: name ?? this.name,
    jobName: jobName,
    machineName: machineName,
    endpoint: endpoint,
    jobCommand: jobCommand,
    benchCommand: benchCommand,
    server: server,
    createdAt: createdAt,
    params: params,
    totalSeconds: totalSeconds,
    totalEvents: totalEvents,
    totalRequests: totalRequests,
    tokensPerSecond: tokensPerSecond,
    requestsPerSecond: requestsPerSecond,
    maxSeq: maxSeq,
    errorCount: errorCount,
    errorSample: errorSample,
    cancelled: cancelled,
    stats: stats,
    series: series,
    ttftHistogram: ttftHistogram,
    itlHistogram: itlHistogram,
    chips: chips,
    joulesPerToken: joulesPerToken,
  );

  /// Server label for badges — 'zml' reads better as 'llmd' in this app.
  String get serverLabel => switch (server) {
    'zml' => 'llmd',
    '' || 'unknown' => 'unknown',
    _ => server,
  };

  Map<String, dynamic> toMap() => {
    'jobName': jobName,
    'jobCommand': jobCommand,
    'benchCommand': benchCommand,
    'params': params.toMap(),
    'totalSeconds': totalSeconds,
    'totalEvents': totalEvents,
    'maxSeq': maxSeq,
    if (errorSample != null) 'errorSample': errorSample,
    'errorCount': errorCount,
    'cancelled': cancelled,
    'stats': [for (final s in stats) s.toMap()],
    'series': [for (final s in series) s.toMap()],
    'ttft': ttftHistogram.toMap(),
    'itl': itlHistogram.toMap(),
    if (chips.isNotEmpty) 'chips': [for (final c in chips) c.toMap()],
    'jpt': ?joulesPerToken,
  };

  /// Rebuilds a report from its DB row: the scalar list-display columns plus
  /// the JSON blob holding everything else.
  factory PerfReport.fromParts({
    required String id,
    required String name,
    required String machineName,
    required String endpoint,
    required String server,
    required DateTime createdAt,
    required int totalRequests,
    required double tokensPerSecond,
    required double requestsPerSecond,
    required Map<String, dynamic> m,
  }) => PerfReport(
    id: id,
    name: name,
    jobName: m['jobName'] as String? ?? '',
    machineName: machineName,
    endpoint: endpoint,
    jobCommand: m['jobCommand'] as String? ?? '',
    benchCommand: m['benchCommand'] as String? ?? '',
    server: server,
    createdAt: createdAt,
    params: PerfParams.fromMap(
      (m['params'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    totalSeconds: (m['totalSeconds'] as num?)?.toDouble() ?? 0,
    totalEvents: (m['totalEvents'] as num?)?.toInt() ?? 0,
    totalRequests: totalRequests,
    tokensPerSecond: tokensPerSecond,
    requestsPerSecond: requestsPerSecond,
    maxSeq: (m['maxSeq'] as num?)?.toInt() ?? 0,
    errorCount: (m['errorCount'] as num?)?.toInt() ?? 0,
    errorSample: m['errorSample'] as String?,
    cancelled: m['cancelled'] as bool? ?? false,
    stats: [
      for (final s in (m['stats'] as List? ?? const []))
        PerfStatRow.fromMap((s as Map).cast<String, dynamic>()),
    ],
    series: [
      for (final s in (m['series'] as List? ?? const []))
        PerfSeriesPoint.fromMap((s as Map).cast<String, dynamic>()),
    ],
    ttftHistogram: PerfHistogram.fromMap(
      (m['ttft'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    itlHistogram: PerfHistogram.fromMap(
      (m['itl'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    chips: [
      for (final c in (m['chips'] as List? ?? const []))
        PerfChipStat.fromMap((c as Map).cast<String, dynamic>()),
    ],
    joulesPerToken: (m['jpt'] as num?)?.toDouble(),
  );
}
