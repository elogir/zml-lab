import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark.dart';

Color benchmarkStatusColor(BenchmarkRequestStatus status, AppColors c) =>
    switch (status) {
      BenchmarkRequestStatus.queued => c.textMuted,
      BenchmarkRequestStatus.streaming => c.statusStarting,
      BenchmarkRequestStatus.done => c.statusRunning,
      BenchmarkRequestStatus.failed => c.statusFailed,
    };

/// One streaming request in the benchmark grid.
class BenchmarkRequestCard extends StatelessWidget {
  const BenchmarkRequestCard({
    super.key,
    required this.request,
    this.onExpand,
    this.expanded = false,
  });

  final BenchmarkRequest request;
  final VoidCallback? onExpand;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = benchmarkStatusColor(request.status, c);

    // The whole card is the affordance: it highlights on hover and opens the
    // fullscreen focus view on tap (no separate expand button).
    return AppCard(
      onTap: onExpand,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                request.index.toString().padLeft(2, '0'),
                style: context.text.monoSmall.copyWith(color: c.textSecondary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                request.status.label,
                style: context.text.small.copyWith(color: dot),
              ),
              const Spacer(),
              Text(
                request.tokensPerSecond > 0
                    ? request.tokensPerSecond.toStringAsFixed(1)
                    : '—',
                style: context.text.mono.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.statusRunning,
                ),
              ),
              const SizedBox(width: 3),
              Text('t/s', style: context.text.monoSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ClipRect(
              child: Text(
                request.text.isEmpty ? '…' : request.text,
                style: context.text.monoSmall.copyWith(
                  color: c.textSecondary,
                  height: 1.5,
                ),
                maxLines: expanded ? null : 5,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _Metric(label: 'ttft', value: _ms(request.ttftMs)),
              const SizedBox(width: AppSpacing.lg),
              _Metric(label: 'tok', value: '${request.tokens}'),
              const SizedBox(width: AppSpacing.lg),
              _Metric(label: 'lat', value: _ms(request.latencyMs)),
            ],
          ),
        ],
      ),
    );
  }

  String _ms(int? v) => v == null ? '—' : '${v}ms';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Text(label, style: context.text.monoSmall.copyWith(color: c.textFaint)),
        const SizedBox(width: 5),
        Text(value, style: context.text.monoSmall),
      ],
    );
  }
}
