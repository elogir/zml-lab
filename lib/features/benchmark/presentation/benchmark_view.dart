import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark.dart';
import '../application/benchmark_controller.dart';
import 'benchmark_focus.dart';
import 'benchmark_prompt_editor.dart';
import 'benchmark_request_card.dart';

/// Benchmark/test mode for a running job: fire a batch of requests and watch
/// each stream its response with a live tokens/sec reading.
class BenchmarkView extends ConsumerStatefulWidget {
  const BenchmarkView({
    super.key,
    required this.jobId,
    required this.endpoint,
  });

  final String jobId;
  final String endpoint;

  @override
  ConsumerState<BenchmarkView> createState() => _BenchmarkViewState();
}

class _BenchmarkViewState extends ConsumerState<BenchmarkView> {
  late final TextEditingController _prompt;
  late final TextEditingController _batch;

  @override
  void initState() {
    super.initState();
    // Seed the fields from the (keep-alive) run state rather than hard-coded
    // defaults, so the prompt and batch size the user last set are restored
    // when they come back to the tab. Edits are written straight back below.
    final run = ref.read(benchmarkControllerProvider(widget.jobId));
    _prompt = TextEditingController(text: run.prompt);
    _batch = TextEditingController(text: '${run.batchSize}');
  }

  @override
  void dispose() {
    _prompt.dispose();
    _batch.dispose();
    super.dispose();
  }

  BenchmarkController get _controller =>
      ref.read(benchmarkControllerProvider(widget.jobId).notifier);

  void _send() => _controller.start();

  Future<void> _editPrompt() async {
    await showBenchmarkPromptEditor(context, widget.jobId);
    if (!mounted) return;
    // The editor writes through to run state; mirror it back into the inline
    // field so the two stay in sync once the popup closes.
    final prompt = ref.read(benchmarkControllerProvider(widget.jobId)).prompt;
    if (_prompt.text != prompt) _prompt.text = prompt;
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(benchmarkControllerProvider(widget.jobId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Controls(
          prompt: _prompt,
          batch: _batch,
          running: run.isRunning,
          onSend: _send,
          onCancel: _controller.cancel,
          onExpandPrompt: _editPrompt,
          onPromptChanged: _controller.setPrompt,
          onBatchChanged: (v) {
            final n = int.tryParse(v);
            if (n != null) _controller.setBatchSize(n);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _AggregateBar(run: run),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: run.requests.isEmpty
              ? _EmptyState(endpoint: widget.endpoint)
              : _Grid(run: run, jobId: widget.jobId),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.prompt,
    required this.batch,
    required this.running,
    required this.onSend,
    required this.onCancel,
    required this.onExpandPrompt,
    required this.onPromptChanged,
    required this.onBatchChanged,
  });

  final TextEditingController prompt;
  final TextEditingController batch;
  final bool running;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onExpandPrompt;
  final ValueChanged<String> onPromptChanged;
  final ValueChanged<String> onBatchChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: prompt,
            prefix: '>',
            mono: true,
            onChanged: onPromptChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButton(
          icon: AppIcons.fullscreen,
          size: 15,
          padding: const EdgeInsets.all(9),
          onPressed: onExpandPrompt,
        ),
        const SizedBox(width: AppSpacing.lg),
        Text('Batch size', style: context.text.smallMuted),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 64,
          child: AppTextField(
            controller: batch,
            mono: true,
            onChanged: onBatchChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppButton(
          label: 'Send batch',
          icon: AppIcons.send,
          variant: AppButtonVariant.primary,
          onPressed: onSend,
        ),
        if (running) ...[
          const SizedBox(width: AppSpacing.sm),
          AppIconButton(
            icon: AppIcons.kill,
            size: 15,
            color: c.statusFailed,
            padding: const EdgeInsets.all(9),
            onPressed: onCancel,
          ),
        ],
      ],
    );
  }
}

class _AggregateBar extends StatelessWidget {
  const _AggregateBar({required this.run});

  final BenchmarkRun run;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _Stat(
            label: 'AGGREGATE',
            value: run.aggregateTokensPerSecond.toStringAsFixed(1),
            unit: 'tok/s',
            // Green only while the reading is still live (all requests at full
            // concurrency). Once it freezes at the first completion it turns
            // neutral, signalling a locked-in result rather than a live number.
            valueColor: run.isRunning && !run.aggregateFrozen
                ? c.statusRunning
                : null,
          ),
          const SizedBox(width: AppSpacing.xxl),
          _Stat(
            label: 'COMPLETED',
            value: '${run.completed}',
            // Denominator is the batch actually in flight, not the (editable)
            // batch-size setting — so tweaking the field for the next run
            // doesn't skew the current run's count.
            unit: '/${run.requests.isEmpty ? run.batchSize : run.requests.length}',
          ),
          const SizedBox(width: AppSpacing.xxl),
          _Stat(
            label: 'MEDIAN TTFT',
            value: '${run.medianTtftMs}',
            unit: 'ms',
          ),
          const SizedBox(width: AppSpacing.xxl),
          _Stat(
            label: 'ELAPSED',
            value: (run.elapsed.inMilliseconds / 1000).toStringAsFixed(1),
            unit: 's',
          ),
          const Spacer(),
          if (run.isRunning) _StreamingPill(),
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

class _StreamingPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: c.statusStarting,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'streaming',
          style: context.text.small.copyWith(color: c.statusStarting),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.run, required this.jobId});

  final BenchmarkRun run;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: 172,
      ),
      itemCount: run.requests.length,
      itemBuilder: (context, i) {
        final request = run.requests[i];
        return BenchmarkRequestCard(
          request: request,
          onExpand: () => showBenchmarkFocus(context, jobId, request.index),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.endpoint});

  final String endpoint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.benchmark, size: 26, color: c.textFaint),
          const SizedBox(height: AppSpacing.md),
          Text('No benchmark running', style: context.text.bodySecondary),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set a batch size and send requests to ',
                  style: context.text.smallMuted),
              Text(endpoint, style: context.text.monoSmall),
            ],
          ),
        ],
      ),
    );
  }
}
