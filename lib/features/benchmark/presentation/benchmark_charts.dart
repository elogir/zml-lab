import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chart_trackball.dart';
import '../../../core/widgets/smooth_live_series.dart';
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
  const BenchmarkCharts({super.key, required this.samples, this.live = false});

  final List<BenchmarkSample> samples;

  /// While a batch streams: drawn every frame, the newest stretch gliding
  /// between samples (see [SmoothLiveSeries]).
  final bool live;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SmoothLiveSeries<BenchmarkSample>(
      points: samples,
      live: live,
      timeMs: (s) => s.elapsedMs,
      lerp: (a, b, t, atMs) => BenchmarkSample(
        elapsedMs: atMs,
        tps: a.tps + (b.tps - a.tps) * t,
        avgTps: a.avgTps + (b.avgTps - a.avgTps) * t,
        tokens: (a.tokens + (b.tokens - a.tokens) * t).round(),
      ),
      builder: (context, samples) => _charts(context, c, samples),
    );
  }

  Widget _charts(
    BuildContext context,
    AppColors c,
    List<BenchmarkSample> samples,
  ) {
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
    // Ranges that move in steps, not with every live update (each change
    // drops the hover readout — see ChartTrackball).
    final step = _niceStep(maxSec);
    final maxY = samples.map(value).fold(0.0, math.max);
    final maxima = Offset((maxSec / step).ceil() * step, stableAxisMax(maxY));
    // When a range steps up the plot rescales over a moment, not in one
    // frame — outside ChartTrackball, so each frame of it refreshes the
    // readout too.
    return TweenAnimationBuilder<Offset>(
      tween: Tween(end: maxima),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, max, _) => ChartTrackball(
        builder: (context, trackball) => SfCartesianChart(
          backgroundColor: const Color(0x00000000),
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          primaryXAxis: NumericAxis(
            // Start at 0 with a whole-number interval so labels read 0s, 1s,
            // 2s… rather than the axis's data-driven 0.11s / 0.61s.
            minimum: 0,
            maximum: max.dx,
            interval: step,
            labelFormat: '{value}s',
            labelStyle: label,
            axisLine: AxisLine(width: 0.5, color: c.borderMuted),
            majorTickLines: const MajorTickLines(size: 0),
            majorGridLines: MajorGridLines(width: 0.5, color: c.borderMuted),
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: max.dy,
            labelStyle: label,
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            majorGridLines: MajorGridLines(width: 0.5, color: c.borderMuted),
          ),
          trackballBehavior: trackball,
          series: <CartesianSeries<BenchmarkSample, double>>[
            AreaSeries<BenchmarkSample, double>(
              dataSource: samples,
              xValueMapper: (s, _) => s.elapsedMs / 1000.0,
              yValueMapper: (s, _) => value(s),
              name: 'tok/s',
              color: color.withValues(alpha: 0.14),
              borderColor: color,
              borderWidth: 2,
              // Live and readable (see ChartTrackball).
              animationDuration: 0,
            ),
          ],
        ),
      ),
    );
  }
}
