import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/benchmark.dart';
import 'benchmark_request_card.dart' show benchmarkStatusColor;

/// The benchmark charts, shared by the live view and the saved-run detail:
/// aggregate throughput over time (its slope is the story), and the
/// per-request tok/s and time-to-first-token breakdowns.
class BenchmarkCharts extends StatelessWidget {
  const BenchmarkCharts({
    super.key,
    required this.samples,
    required this.requests,
  });

  final List<BenchmarkSample> samples;
  final List<BenchmarkRequest> requests;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChartCard(
            title: 'Throughput over time',
            unit: 'tok/s',
            height: 260,
            child: _ThroughputChart(samples: samples),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChartCard(
            title: 'Per-request throughput',
            unit: 'tok/s',
            height: 200,
            child: _PerRequestChart(
              requests: requests,
              value: (r) => r.tokensPerSecond,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChartCard(
            title: 'Time to first token',
            unit: 'ms',
            height: 200,
            child: _PerRequestChart(
              requests: requests,
              value: (r) => (r.ttftMs ?? 0).toDouble(),
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
  const _ThroughputChart({required this.samples});

  final List<BenchmarkSample> samples;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (samples.length < 2) {
      return _empty(context, 'Not enough data yet');
    }
    final label = context.text.monoSmall.copyWith(color: c.textFaint);
    return SfCartesianChart(
      backgroundColor: const Color(0x00000000),
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      legend: Legend(
        isVisible: true,
        position: LegendPosition.top,
        alignment: ChartAlignment.near,
        textStyle: context.text.monoSmall.copyWith(color: c.textMuted),
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      primaryXAxis: NumericAxis(
        title: AxisTitle(text: 'seconds', textStyle: label),
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
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
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
          yValueMapper: (s, _) => s.tps,
          name: 'aggregate',
          color: c.statusRunning.withValues(alpha: 0.14),
          borderColor: c.statusRunning,
          borderWidth: 2,
        ),
        LineSeries<BenchmarkSample, double>(
          dataSource: samples,
          xValueMapper: (s, _) => s.elapsedMs / 1000.0,
          yValueMapper: (s, _) => s.avgTps,
          name: 'avg / request',
          color: c.accent,
          width: 2,
          dashArray: const [5, 4],
        ),
      ],
    );
  }
}

class _PerRequestChart extends StatelessWidget {
  const _PerRequestChart({required this.requests, required this.value});

  final List<BenchmarkRequest> requests;
  final double Function(BenchmarkRequest) value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (requests.isEmpty) return _empty(context, 'No requests');
    final label = context.text.monoSmall.copyWith(color: c.textFaint);
    return SfCartesianChart(
      backgroundColor: const Color(0x00000000),
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: NumericAxis(
        title: AxisTitle(text: 'request', textStyle: label),
        labelStyle: label,
        interval: requests.length > 20 ? null : 1,
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
      series: <CartesianSeries<BenchmarkRequest, num>>[
        ColumnSeries<BenchmarkRequest, num>(
          dataSource: requests,
          xValueMapper: (r, _) => r.index,
          yValueMapper: (r, _) => value(r),
          pointColorMapper: (r, _) => benchmarkStatusColor(r.status, c),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        ),
      ],
    );
  }
}

Widget _empty(BuildContext context, String message) => Center(
  child: Text(message, style: context.text.smallMuted),
);
