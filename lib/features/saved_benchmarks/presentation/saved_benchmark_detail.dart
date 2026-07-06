import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark.dart';
import '../../../models/saved_benchmark.dart';
import '../../../repositories/saved_benchmark_repository.dart';
import '../../benchmark/presentation/benchmark_charts.dart';
import '../../benchmark/presentation/benchmark_request_card.dart';
import '../../benchmark/presentation/reasoning_view.dart';

/// Opens a saved benchmark: its headline stats, the prompt, and every saved
/// response.
Future<void> showSavedBenchmarkDetail(
  BuildContext context,
  SavedBenchmark benchmark,
) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _DetailView(benchmark: benchmark),
      transitionsBuilder: (context, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

class _DetailView extends ConsumerStatefulWidget {
  const _DetailView({required this.benchmark});

  final SavedBenchmark benchmark;

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

enum _DetailTab { responses, charts }

class _DetailViewState extends ConsumerState<_DetailView> {
  late SavedBenchmark _b = widget.benchmark;
  bool _editingName = false;
  _DetailTab _tab = _DetailTab.responses;
  late final TextEditingController _name = TextEditingController(
    text: widget.benchmark.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _commitName() {
    final name = _name.text.trim();
    setState(() => _editingName = false);
    if (name.isEmpty || name == _b.name) {
      _name.text = _b.name; // revert an empty/unchanged edit
      return;
    }
    final updated = _b.copyWith(name: name);
    setState(() => _b = updated);
    ref.read(savedBenchmarkRepositoryProvider).save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final b = _b;

    final size = MediaQuery.sizeOf(context);
    final width = (size.width * 0.62).clamp(480.0, 1100.0);
    final height = (size.height * 0.72).clamp(380.0, 900.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: height),
          child: AppPanel(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fixed-height slot sized to the dense field, so
                          // toggling edit mode doesn't shift the layout below;
                          // the check button sits where the pencil was.
                          SizedBox(
                            height: 28,
                            child: _editingName
                                ? Row(
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 320,
                                        ),
                                        child: AppTextField(
                                          controller: _name,
                                          dense: true,
                                          autofocus: true,
                                          onSubmitted: (_) => _commitName(),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      AppIconButton(
                                        icon: AppIcons.check,
                                        size: 13,
                                        onPressed: _commitName,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          b.name,
                                          style: context.text.bodyStrong,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      AppIconButton(
                                        icon: AppIcons.edit,
                                        size: 13,
                                        onPressed: () => setState(
                                          () => _editingName = true,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                AppIcons.machines,
                                size: 12,
                                color: c.textFaint,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${b.machineLabel} ${b.portLabel}',
                                style: context.text.monoSmall,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                formatAgo(b.createdAt),
                                style: context.text.smallMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Stats(benchmark: b),
                const SizedBox(height: AppSpacing.lg),
                AppPanel(
                  color: c.surfaceMuted,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppSelectionArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '>',
                          style: context.text.monoSmall.copyWith(
                            color: c.statusRunning,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            b.prompt,
                            style: context.text.mono.copyWith(
                              color: c.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (b.command.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppPanel(
                    color: c.surfaceMuted,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppSelectionArea(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r'$',
                            style: context.text.monoSmall.copyWith(
                              color: c.textFaint,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              b.command,
                              style: context.text.monoSmall.copyWith(
                                color: c.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          CopyButton(text: b.command),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    SectionLabel(
                      _tab == _DetailTab.charts ? 'Charts' : 'Responses',
                    ),
                    if (_tab == _DetailTab.responses) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${b.requests.length}',
                        style: context.text.smallMuted,
                      ),
                    ],
                    const Spacer(),
                    // Only offer the charts tab when there's a time-series to
                    // plot (older saved runs predate sampling).
                    if (b.samples.length >= 2)
                      SegmentedControl<_DetailTab>(
                        value: _tab,
                        onChanged: (v) => setState(() => _tab = v),
                        options: const [
                          SegmentOption(
                            value: _DetailTab.responses,
                            label: 'Responses',
                            icon: AppIcons.grid,
                          ),
                          SegmentOption(
                            value: _DetailTab.charts,
                            label: 'Charts',
                            icon: AppIcons.chart,
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _tab == _DetailTab.charts
                      ? BenchmarkCharts(samples: b.samples)
                      : b.requests.isEmpty
                      ? Center(
                          child: Text(
                            'No responses saved',
                            style: context.text.smallMuted,
                          ),
                        )
                      // Previews aren't selectable — click one to expand it;
                      // selection lives in the popup with the full text.
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: b.requests.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) =>
                              _Response(request: b.requests[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.benchmark});

  final SavedBenchmark benchmark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final b = benchmark;
    return AppPanel(
      color: c.surfaceMuted,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _Stat(
            label: 'AGGREGATE',
            value: b.aggregateTokensPerSecond.toStringAsFixed(1),
            unit: 'tok/s',
          ),
          const SizedBox(width: AppSpacing.xxl),
          _Stat(label: 'BATCH', value: '${b.batchSize}', unit: ''),
          const SizedBox(width: AppSpacing.xxl),
          _Stat(
            label: 'COMPLETED',
            value: '${b.completed}',
            unit: '/${b.batchSize}',
          ),
          const SizedBox(width: AppSpacing.xxl),
          _Stat(label: 'MEDIAN TTFT', value: '${b.medianTtftMs}', unit: 'ms'),
          const SizedBox(width: AppSpacing.xxl),
          _Stat(
            label: 'ELAPSED',
            value: (b.elapsedMs / 1000).toStringAsFixed(1),
            unit: 's',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

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
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(unit, style: context.text.monoSmall),
            ],
          ],
        ),
      ],
    );
  }
}

class _Response extends StatelessWidget {
  const _Response({required this.request});

  final BenchmarkRequest request;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = request;
    return AppCard(
      onTap: () => _showResponsePopup(context, r),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponseHeader(request: r),
          const SizedBox(height: AppSpacing.sm),
          if (r.text.isEmpty && r.reasoning.isEmpty)
            Text(
              '—',
              style: context.text.monoSmall.copyWith(
                color: c.textSecondary,
                height: 1.5,
              ),
            )
          else
            // Capped preview — a long response crops here; clicking the card
            // opens the full text in a popup stacked over this one.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ClipRect(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.reasoning.isNotEmpty)
                        ReasoningView(r.reasoning, dense: true),
                      if (r.text.isNotEmpty)
                        AppMarkdown(
                          r.text,
                          style: context.text.small.copyWith(
                            color: c.textSecondary,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _ResponseMetrics(request: r),
        ],
      ),
    );
  }
}

/// Status dot + index on the left, tok/s reading on the right.
class _ResponseHeader extends StatelessWidget {
  const _ResponseHeader({required this.request});

  final BenchmarkRequest request;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = request;
    final dot = benchmarkStatusColor(r.status, c);
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          r.index.toString().padLeft(2, '0'),
          style: context.text.monoSmall.copyWith(color: c.textSecondary),
        ),
        if (r.truncated) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            '· truncated',
            style: context.text.small.copyWith(color: c.statusStarting),
          ),
        ],
        const Spacer(),
        Text(
          r.tokensPerSecond.toStringAsFixed(1),
          style: context.text.mono.copyWith(
            fontWeight: FontWeight.w600,
            color: c.statusRunning,
          ),
        ),
        const SizedBox(width: 3),
        Text('t/s', style: context.text.monoSmall),
      ],
    );
  }
}

class _ResponseMetrics extends StatelessWidget {
  const _ResponseMetrics({required this.request});

  final BenchmarkRequest request;

  String _ms(int? v) => v == null ? '—' : '${v}ms';

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Row(
      children: [
        _metric(context, 'ttft', _ms(r.ttftMs)),
        const SizedBox(width: AppSpacing.lg),
        _metric(context, 'tok', '${r.tokens}'),
        const SizedBox(width: AppSpacing.lg),
        _metric(context, 'lat', _ms(r.latencyMs)),
      ],
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
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

/// The full response, stacked in its own popup over the detail view.
void _showResponsePopup(BuildContext context, BenchmarkRequest request) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _ResponsePopup(request: request),
      transitionsBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _ResponsePopup extends StatelessWidget {
  const _ResponsePopup({required this.request});

  final BenchmarkRequest request;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = request;
    final size = MediaQuery.sizeOf(context);
    final height = (size.height * 0.7).clamp(360.0, 860.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: height),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppPanel(
            color: c.surface,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _ResponseHeader(request: r)),
                    const SizedBox(width: AppSpacing.md),
                    CopyButton(text: r.text),
                    const SizedBox(width: AppSpacing.sm),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Flexible(
                  child: AppPanel(
                    color: c.surfaceMuted,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppSelectionArea(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r.reasoning.isNotEmpty)
                              ReasoningView(r.reasoning),
                            AppMarkdown(
                              r.text.isEmpty && r.reasoning.isEmpty
                                  ? '—'
                                  : r.text,
                              style: context.text.small.copyWith(
                                color: c.textSecondary,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ResponseMetrics(request: r),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
