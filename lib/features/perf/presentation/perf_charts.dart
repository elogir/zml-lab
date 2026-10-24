import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chart_trackball.dart';
import '../../../core/widgets/smooth_live_series.dart';
import '../../../models/perf_report.dart';

/// Chart styling shared with the chat-benchmark charts: flat area fills,
/// hairline grid, mono axis labels, trackball instead of tooltips.

/// How long an axis takes to settle on a new range.
const _rescale = Duration(milliseconds: 250);

double _niceStep(double maxX) {
  final target = maxX <= 0 ? 1.0 : maxX / 5.0;
  const steps = [0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 1200];
  for (final s in steps) {
    if (target <= s) return s.toDouble();
  }
  return 3600;
}

/// The live charts while a run streams: the server's token throughput and
/// the requests in flight — drawn every frame, the newest stretch gliding
/// between samples (see [SmoothLiveSeries]).
class PerfLiveCharts extends StatelessWidget {
  const PerfLiveCharts({super.key, required this.series, this.live = true});

  final List<PerfSeriesPoint> series;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SmoothLiveSeries<PerfSeriesPoint>(
      points: series,
      live: live,
      timeMs: (p) => p.elapsedMs,
      lerp: (a, b, t, atMs) => PerfSeriesPoint(
        elapsedMs: atMs,
        tps: a.tps + (b.tps - a.tps) * t,
        active: (a.active + (b.active - a.active) * t).round(),
        waiting: (a.waiting + (b.waiting - a.waiting) * t).round(),
        requests: a.requests,
      ),
      builder: (context, shown) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PerfChartCard(
            title: 'Throughput',
            unit: 'tok/s',
            height: 200,
            child: PerfSeriesChart(
              series: shown,
              value: (s) => s.tps,
              color: c.statusRunning,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PerfRequestsCard(series: shown, height: 160),
        ],
      ),
    );
  }
}

/// Requests in flight over the run, and — shaded over them — how many were
/// still waiting for their first token (queued, or in prefill).
class PerfRequestsCard extends StatelessWidget {
  const PerfRequestsCard({
    super.key,
    required this.series,
    required this.height,
  });

  final List<PerfSeriesPoint> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PerfChartCard(
      title: 'Requests in flight',
      unit: 'waiting for a first token shaded',
      height: height,
      child: PerfSeriesChart(
        series: series,
        value: (s) => s.active.toDouble(),
        name: 'in flight',
        color: c.accent,
        overlay: (
          value: (s) => s.waiting.toDouble(),
          name: 'waiting',
          color: c.statusStarting,
        ),
        stepped: true,
      ),
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

/// Time series over the run — an area (throughput) or step line (requests),
/// with an optional [overlay] series drawn over it.
class PerfSeriesChart extends StatelessWidget {
  const PerfSeriesChart({
    super.key,
    required this.series,
    required this.value,
    required this.color,
    this.name,
    this.overlay,
    this.stepped = false,
  });

  final List<PerfSeriesPoint> series;
  final double Function(PerfSeriesPoint) value;
  final Color color;

  /// The series' name in the hover readout (needed once there are two).
  final String? name;
  final ({double Function(PerfSeriesPoint) value, String name, Color color})?
  overlay;
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
    // Ranges that move in steps, not with every live update (each change
    // drops the hover readout — see ChartTrackball).
    final step = _niceStep(maxSec);
    final maxY = series.map(value).fold(0.0, math.max);
    final maxima = Offset((maxSec / step).ceil() * step, stableAxisMax(maxY));
    // When a range steps up the plot rescales over a moment, not in one
    // frame — outside ChartTrackball, so each frame of it refreshes the
    // readout too.
    return TweenAnimationBuilder<Offset>(
      tween: Tween(end: maxima),
      duration: _rescale,
      curve: Curves.easeOut,
      builder: (context, max, _) => ChartTrackball(
        builder: (context, trackball) => SfCartesianChart(
          backgroundColor: const Color(0x00000000),
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          primaryXAxis: NumericAxis(
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
          // No animation: shown as is, live or finished (see ChartTrackball).
          series: <CartesianSeries<PerfSeriesPoint, double>>[
            if (stepped) ...[
              StepAreaSeries<PerfSeriesPoint, double>(
                dataSource: series,
                name: name,
                xValueMapper: (s, _) => s.elapsedMs / 1000.0,
                yValueMapper: (s, _) => value(s),
                color: color.withValues(alpha: 0.14),
                borderColor: color,
                borderWidth: 2,
                animationDuration: 0,
              ),
              if (overlay case final o?)
                StepAreaSeries<PerfSeriesPoint, double>(
                  dataSource: series,
                  name: o.name,
                  xValueMapper: (s, _) => s.elapsedMs / 1000.0,
                  yValueMapper: (s, _) => o.value(s),
                  color: o.color.withValues(alpha: 0.30),
                  borderColor: o.color,
                  borderWidth: 1,
                  animationDuration: 0,
                ),
            ] else
              AreaSeries<PerfSeriesPoint, double>(
                dataSource: series,
                xValueMapper: (s, _) => s.elapsedMs / 1000.0,
                yValueMapper: (s, _) => value(s),
                color: color.withValues(alpha: 0.14),
                borderColor: color,
                borderWidth: 2,
                animationDuration: 0,
              ),
          ],
        ),
      ),
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
      return Center(child: Text('No data', style: context.text.smallMuted));
    }
    final label = context.text.monoSmall.copyWith(color: c.textFaint);
    return ChartTrackball(
      builder: (context, trackball) => SfCartesianChart(
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
        trackballBehavior: trackball,
        series: <CartesianSeries<_Bin, double>>[
          ColumnSeries<_Bin, double>(
            dataSource: bins,
            xValueMapper: (b, _) => b.x,
            yValueMapper: (b, _) => b.count,
            color: color.withValues(alpha: 0.45),
            borderColor: color,
            borderWidth: 1,
            width: 0.92,
            animationDuration: 0,
          ),
        ],
      ),
    );
  }
}
