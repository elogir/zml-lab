import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/perf_report.dart';

/// Chart styling shared with the chat-benchmark charts: flat area fills,
/// hairline grid, mono axis labels, trackball instead of tooltips.

double _niceStep(double maxX) {
  final target = maxX <= 0 ? 1.0 : maxX / 5.0;
  const steps = [0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 1200];
  for (final s in steps) {
    if (target <= s) return s.toDouble();
  }
  return 3600;
}

/// The live charts while a run streams (and the top of the report): the
/// server's total event throughput and how many requests were streaming.
class PerfLiveCharts extends StatelessWidget {
  const PerfLiveCharts({super.key, required this.series});

  final List<PerfSeriesPoint> series;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PerfChartCard(
          title: 'Throughput',
          unit: 'tok/s',
          height: 200,
          child: PerfSeriesChart(
            series: series,
            value: (s) => s.tps,
            color: c.statusRunning,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PerfChartCard(
          title: 'Streaming requests',
          unit: 'concurrent',
          height: 160,
          child: PerfSeriesChart(
            series: series,
            value: (s) => s.active.toDouble(),
            color: c.accent,
            stepped: true,
          ),
        ),
      ],
    );
  }
}

/// A bordered card holding one chart, matching the benchmark tab's cards.
class PerfChartCard extends StatelessWidget {
  const PerfChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.height,
    required this.child,
  });

  final String title;
  final String unit;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: c.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title, style: context.text.bodyStrong),
              const Spacer(),
              Text(unit, style: context.text.smallMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

/// Time series over the run — an area (throughput) or step line (requests).
class PerfSeriesChart extends StatelessWidget {
  const PerfSeriesChart({
    super.key,
    required this.series,
    required this.value,
    required this.color,
    this.stepped = false,
  });

  final List<PerfSeriesPoint> series;
  final double Function(PerfSeriesPoint) value;
  final Color color;
  final bool stepped;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (series.length < 2) {
      return Center(
        child: Text('Not enough data yet', style: context.text.smallMuted),
      );
    }
    final label = context.text.monoSmall.copyWith(color: c.textFaint);
    final maxSec = series.last.elapsedMs / 1000.0;
    return SfCartesianChart(
      backgroundColor: const Color(0x00000000),
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: NumericAxis(
        minimum: 0,
        interval: _niceStep(maxSec),
        labelFormat: '{value}s',
        labelStyle: label,
        axisLine: AxisLine(width: 0.5, color: c.borderMuted),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.borderMuted),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: label,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.borderMuted),
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineColor: c.borderStrong,
        tooltipSettings: InteractiveTooltip(
          color: c.surface,
          textStyle: context.text.monoSmall.copyWith(color: c.textPrimary),
          borderColor: c.borderStrong,
          borderWidth: 1,
        ),
      ),
      series: <CartesianSeries<PerfSeriesPoint, double>>[
        if (stepped)
          StepAreaSeries<PerfSeriesPoint, double>(
            dataSource: series,
            xValueMapper: (s, _) => s.elapsedMs / 1000.0,
            yValueMapper: (s, _) => value(s),
            color: color.withValues(alpha: 0.14),
            borderColor: color,
            borderWidth: 2,
          )
        else
          AreaSeries<PerfSeriesPoint, double>(
            dataSource: series,
            xValueMapper: (s, _) => s.elapsedMs / 1000.0,
            yValueMapper: (s, _) => value(s),
            color: color.withValues(alpha: 0.14),
            borderColor: color,
            borderWidth: 2,
          ),
      ],
    );
  }
}

class _Bin {
  const _Bin(this.x, this.count);

  final double x;
  final int count;
}

/// Latency distribution as columns, from a pre-bucketed [PerfHistogram].
class PerfHistogramChart extends StatelessWidget {
  PerfHistogramChart.fromHistogram({
    super.key,
    required PerfHistogram histogram,
    required this.color,
  }) : _bins = [
         for (var i = 0; i < histogram.counts.length; i++)
           _Bin(
             histogram.binStartMs + (i + 0.5) * histogram.binWidthMs,
             histogram.counts[i],
           ),
       ];

  final List<_Bin> _bins;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bins = _bins;
    if (bins.isEmpty) {
      return Center(
        child: Text('No data', style: context.text.smallMuted),
      );
    }
    final label = context.text.monoSmall.copyWith(color: c.textFaint);
    return SfCartesianChart(
      backgroundColor: const Color(0x00000000),
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: NumericAxis(
        labelFormat: '{value}ms',
        labelStyle: label,
        axisLine: AxisLine(width: 0.5, color: c.borderMuted),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: label,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.borderMuted),
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineColor: c.borderStrong,
        tooltipSettings: InteractiveTooltip(
          color: c.surface,
          textStyle: context.text.monoSmall.copyWith(color: c.textPrimary),
          borderColor: c.borderStrong,
          borderWidth: 1,
        ),
      ),
      series: <CartesianSeries<_Bin, double>>[
        ColumnSeries<_Bin, double>(
          dataSource: bins,
          xValueMapper: (b, _) => b.x,
          yValueMapper: (b, _) => b.count,
          color: color.withValues(alpha: 0.45),
          borderColor: color,
          borderWidth: 1,
          width: 0.92,
        ),
      ],
    );
  }
}
