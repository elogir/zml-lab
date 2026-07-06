import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/benchmark.dart';

/// A whole-number-ish axis step giving ~5 ticks over a [maxSec]-long run, so
/// the time axis lands on clean values (…, 1s, 2s, 5s, 10s, 30s, …).
double _niceStep(double maxSec) {
  final target = maxSec <= 0 ? 1.0 : maxSec / 5.0;
  const steps = [0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 1200];
  for (final s in steps) {
    if (target <= s) return s.toDouble();
  }
  return 3600;
}

/// The benchmark charts, shared by the live view and the saved-run detail: two
/// throughput time-series, so the slope is the story — the batch's aggregate
/// tok/s, and the average tok/s across only the still-running requests.
class BenchmarkCharts extends StatelessWidget {
  const BenchmarkCharts({super.key, required this.samples});

  final List<BenchmarkSample> samples;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChartCard(
            title: 'Aggregate throughput',
            unit: 'tok/s',
            height: 240,
            child: _ThroughputChart(
              samples: samples,
              value: (s) => s.tps,
              color: c.statusRunning,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChartCard(
            title: 'Average per request',
            unit: 'tok/s',
            height: 240,
            child: _ThroughputChart(
              samples: samples,
              value: (s) => s.avgTps,
              color: c.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: context.text.bodyStrong),
              const SizedBox(width: AppSpacing.sm),
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

class _ThroughputChart extends StatelessWidget {
  const _ThroughputChart({
    required this.samples,
    required this.value,
    required this.color,
  });

  final List<BenchmarkSample> samples;
  final double Function(BenchmarkSample) value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (samples.length < 2) {
      return Center(
        child: Text('Not enough data yet', style: context.text.smallMuted),
      );
    }
    final label = context.text.monoSmall.copyWith(color: c.textFaint);
    final maxSec = samples.last.elapsedMs / 1000.0;
    return SfCartesianChart(
      backgroundColor: const Color(0x00000000),
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: NumericAxis(
        // Start at 0 with a whole-number interval so labels read 0s, 1s, 2s…
        // rather than the axis's data-driven 0.11s / 0.61s.
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
      series: <CartesianSeries<BenchmarkSample, double>>[
        AreaSeries<BenchmarkSample, double>(
          dataSource: samples,
          xValueMapper: (s, _) => s.elapsedMs / 1000.0,
          yValueMapper: (s, _) => value(s),
          name: 'tok/s',
          color: color.withValues(alpha: 0.14),
          borderColor: color,
          borderWidth: 2,
        ),
      ],
    );
  }
}
