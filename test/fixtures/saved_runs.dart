import 'package:zml_lab/models/perf_report.dart';
import 'package:zml_lab/models/saved_benchmark.dart';

/// A saved perf report with just what the Saved benchmarks tab reads.
PerfReport perfReport(
  String id, {
  String? name,
  String machine = 'GB300-1',
  String model = '',
  int concurrency = 16,
  double tps = 1000,
  double? ttftP50,
  DateTime? createdAt,
}) => PerfReport(
  id: id,
  name: name ?? id,
  jobName: id,
  machineName: machine,
  endpoint: '$machine:8000',
  jobCommand: '',
  benchCommand: '',
  createdAt: createdAt ?? DateTime(2026, 10, 1),
  params: PerfParams(concurrency: concurrency, model: model),
  totalSeconds: 30,
  totalEvents: 1000,
  totalRequests: 100,
  tokensPerSecond: tps,
  requestsPerSecond: 3.3,
  errorCount: 0,
  stats: [
    if (ttftP50 != null)
      PerfStatRow(
        label: 'Time to first token',
        unit: 'ms',
        avg: ttftP50,
        min: ttftP50,
        max: ttftP50,
        p50: ttftP50,
        p75: ttftP50,
        p90: ttftP50,
        p95: ttftP50,
        p99: ttftP50,
        p999: ttftP50,
      ),
  ],
  series: [
    for (var t = 0; t <= 30; t++)
      PerfSeriesPoint(
        elapsedMs: t * 1000,
        tps: tps,
        active: concurrency,
        requests: t * 3,
      ),
  ],
  ttftHistogram: const PerfHistogram(binWidthMs: 1, binStartMs: 0, counts: []),
  itlHistogram: const PerfHistogram(binWidthMs: 1, binStartMs: 0, counts: []),
);

/// A saved chat benchmark with just what the Saved benchmarks tab reads.
SavedBenchmark chatBenchmark(
  String id, {
  String machine = 'local',
  String? model,
  int batch = 4,
  double tps = 200,
  int ttftMs = 100,
  DateTime? createdAt,
}) => SavedBenchmark(
  id: id,
  name: id,
  endpoint: '$machine:8000',
  machineName: machine,
  prompt: 'hi',
  model: model,
  batchSize: batch,
  aggregateTokensPerSecond: tps,
  completed: batch,
  medianTtftMs: ttftMs,
  elapsedMs: 2000,
  createdAt: createdAt ?? DateTime(2026, 10, 1),
);
