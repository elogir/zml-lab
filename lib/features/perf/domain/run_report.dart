/// A perf report rebuilt from a run file (docs/perf-run-format.md) — an
/// imported run. The numbers come from the same accumulators a live run
/// uses, fed the file's rows in the order they were recorded, so they are
/// the run format's and match the report the run had when it was saved.
library;

import '../../../models/perf_report.dart';
import '../../../models/run_meta.dart';
import 'chip_metrics.dart';
import 'perf_stats.dart';
import 'run_recorder_types.dart';

/// The report of the run [meta] and [rows] make up: its id is `run_id`, its
/// details are meta.json's ([RunDetails.fromMeta]; [fallbackName] when it
/// has no label), the machine is `target.machine` (else the target's host).
PerfReport reportFromRun(
  Map<String, Object?> meta,
  RunRows rows, {
  required String fallbackName,
  required DateTime fallbackDate,
}) {
  final acc = PerfAccumulator()..addAll(rows.events);
  final chips = ChipAccumulator();
  for (final (ts, reading) in rows.chips) {
    chips.add(ts, [reading]);
  }

  final target = meta['target'] as Map? ?? const {};
  final url = Uri.tryParse(target['url'] as String? ?? '');
  final machineName = switch (target['machine']) {
    final String m when m.isNotEmpty => m,
    _ => url?.host ?? '',
  };
  final endpoint = url != null && url.hasPort
      ? '$machineName:${url.port}'
      : machineName;

  final p = meta['params'] as Map? ?? const {};
  final params = PerfParams(
    durationSeconds: (p['duration_s'] as num?)?.toInt() ?? 30,
    concurrency: (p['concurrency'] as num?)?.toInt() ?? 16,
    sequenceType: p['prompts'] as String? ?? 'long',
    mode: p['turns'] as String? ?? 'all',
    maxCompletionTokens: (p['max_completion_tokens'] as num?)?.toInt(),
    ignoreEos: p['ignore_eos'] as bool? ?? false,
    // What the requests sent isn't kept apart from the (editable) model.
    model: runMetaField(meta, 'model.name'),
    warmup: p['warmup'] as bool? ?? true,
  );

  DateTime? at(String key) => switch (meta[key]) {
    final String s => DateTime.tryParse(s)?.toLocal(),
    _ => null,
  };

  final details = RunDetails.fromMeta(
    runMetaField(meta, 'label').isEmpty
        ? withRunMetaFields(meta, {'label': fallbackName})
        : meta,
  );
  return PerfReport(
    id: meta['run_id']! as String,
    name: endpoint,
    jobName: endpoint,
    machineName: machineName,
    endpoint: endpoint,
    benchCommand: '',
    createdAt: at('ended_at') ?? at('started_at') ?? fallbackDate,
    params: params,
    totalSeconds: acc.totalSeconds,
    totalEvents: acc.eventCount,
    totalRequests: acc.requestCount,
    tokensPerSecond: acc.tokensPerSecond,
    requestsPerSecond: acc.requestsPerSecond,
    maxSeq: acc.maxSeq,
    errorCount: acc.errorCount,
    errorSample: acc.firstError,
    cancelled: meta['cancelled'] == true,
    stats: acc.statRows(),
    series: acc.series(includeLast: true),
    ttftHistogram: acc.ttftHistogram(),
    itlHistogram: acc.itlHistogram(),
    chips: chips.stats(),
    joulesPerToken: chips.joulesPerToken(acc.tokenCount),
  ).withDetails(details);
}
