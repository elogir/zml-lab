import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/perf_report.dart';
import 'perf_charts.dart';

/// Trims trailing zeros off a 2-decimal stat ("148.87", "397.5", "14").
String formatStat(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return s;
}

/// The full report of a finished perf run: headline throughput, the
/// report.sql statistics table, distribution charts, and the exact command
/// lines (benchmarker + server) the numbers came from.
class PerfReportView extends StatelessWidget {
  const PerfReportView({super.key, required this.report});

  final PerfReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = report;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (r.cancelled) ...[
            _Notice(
              icon: AppIcons.warning,
              text: 'Stopped early — numbers cover the partial run.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (r.errorCount > 0) ...[
            _Notice(
              icon: AppIcons.warning,
              text:
                  '${r.errorCount} request${r.errorCount == 1 ? '' : 's'} '
                  'errored during the run'
                  '${r.errorSample != null ? ': ${r.errorSample}' : '.'}',
              danger: true,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _Headline(report: r),
          const SizedBox(height: AppSpacing.lg),
          _StatsTable(rows: r.stats),
          const SizedBox(height: AppSpacing.lg),
          PerfChartCard(
            title: 'Throughput over the run',
            unit: 'tok/s',
            height: 190,
            child: PerfSeriesChart(
              series: r.series,
              value: (s) => s.tps,
              color: c.statusRunning,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PerfChartCard(
                  title: 'Time to first token',
                  unit: 'requests',
                  height: 170,
                  child: PerfHistogramChart.fromHistogram(
                    histogram: r.ttftHistogram,
                    color: c.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: PerfChartCard(
                  title: 'Inter-token latency',
                  unit: 'gaps',
                  height: 170,
                  child: PerfHistogramChart.fromHistogram(
                    histogram: r.itlHistogram,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PerfChartCard(
            title: 'Streaming requests',
            unit: 'concurrent',
            height: 150,
            child: PerfSeriesChart(
              series: r.series,
              value: (s) => s.active.toDouble(),
              color: c.accent,
              stepped: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _CommandBlock(label: 'Benchmarker', command: r.benchCommand),
          if (r.jobCommand.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _CommandBlock(label: 'Server', command: r.jobCommand),
          ],
        ],
      ),
    );
  }
}

/// Headline numbers + run metadata, in one panel.
class _Headline extends StatelessWidget {
  const _Headline({required this.report});

  final PerfReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = report;
    final meta = [
      r.serverLabel,
      if (r.params.model.isNotEmpty) r.params.model,
      '${r.params.sequenceType} prompts',
      'mode ${r.params.mode}',
      if (r.params.maxCompletionTokens != null)
        'max ${r.params.maxCompletionTokens} tok',
    ].join('  ·  ');
    return AppPanel(
      color: c.surfaceMuted,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xxl,
            runSpacing: AppSpacing.md,
            children: [
              _Stat(
                label: 'THROUGHPUT',
                value: r.tokensPerSecond.toStringAsFixed(1),
                unit: 'tok/s',
                valueColor: c.statusRunning,
              ),
              _Stat(
                label: 'REQUESTS/S',
                value: r.requestsPerSecond.toStringAsFixed(2),
                unit: 'req/s',
              ),
              _Stat(
                label: 'REQUESTS',
                value: '${r.totalRequests}',
                unit: 'total',
              ),
              _Stat(
                label: 'CONCURRENCY',
                value: '${r.params.concurrency}',
                unit: 'workers',
              ),
              _Stat(
                label: 'DURATION',
                value: r.totalSeconds.toStringAsFixed(1),
                unit: 's',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(meta, style: context.text.monoSmall),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.columnHeader),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: context.text.mono.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(unit, style: context.text.monoSmall),
          ],
        ),
      ],
    );
  }
}

/// The statistics table — same rows and columns as the tool's report.sql.
class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.rows});

  final List<PerfStatRow> rows;

  static const _columns = ['avg', 'min', 'max', 'p50', 'p75', 'p90', 'p95', 'p99', 'p99.9'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (rows.isEmpty) return const SizedBox.shrink();
    final header = context.text.columnHeader;
    final mono = context.text.monoSmall.copyWith(color: c.textPrimary);

    TableRow row(PerfStatRow r) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  r.label,
                  style: context.text.small.copyWith(color: c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(r.unit, style: context.text.smallMuted),
            ],
          ),
        ),
        for (final v in [r.avg, r.min, r.max, ...r.percentiles])
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              formatStat(v),
              style: mono,
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
      ],
    );

    return AppPanel(
      padding: EdgeInsets.zero,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2.2)},
        defaultColumnWidth: const FlexColumnWidth(1),
        border: TableBorder(
          horizontalInside: BorderSide(color: c.borderMuted),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text('STATISTIC', style: header),
              ),
              for (final col in _columns)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(col, style: header, textAlign: TextAlign.right),
                ),
            ],
          ),
          for (final r in rows) row(r),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.danger = false});

  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = danger ? c.statusFailed : c.statusStarting;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: context.text.small)),
        ],
      ),
    );
  }
}

/// A labelled one-line command with a copy button, scrolling horizontally.
class _CommandBlock extends StatelessWidget {
  const _CommandBlock({required this.label, required this.command});

  final String label;
  final String command;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: c.borderMuted),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: context.text.columnHeader),
          ),
          Text(
            r'$',
            style: context.text.monoSmall.copyWith(color: c.textFaint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AppSelectionArea(
                child: Text(
                  command,
                  style: context.text.monoSmall.copyWith(
                    color: c.textSecondary,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CopyButton(text: command),
        ],
      ),
    );
  }
}
