import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark.dart';
import '../../saved_benchmarks/presentation/save_benchmark_dialog.dart';
import '../application/benchmark_controller.dart';
import 'benchmark_charts.dart';
import 'benchmark_focus.dart';
import 'benchmark_prompt_editor.dart';
import 'benchmark_request_card.dart';

enum _BenchView { grid, charts }

/// Benchmark/test mode for a running job: fire a batch of requests and watch
/// each stream its response with a live tokens/sec reading.
class BenchmarkView extends ConsumerStatefulWidget {
  const BenchmarkView({
    super.key,
    required this.jobId,
    required this.jobName,
    required this.jobDescription,
    required this.jobCommand,
    required this.machineName,
    required this.endpoint,
    required this.host,
    required this.port,
  });

  final String jobId;

  /// The job's display name — the base of the default name when saving a run.
  final String jobName;

  /// The job's description — appended to the default save name after a
  /// separator, when present.
  final String jobDescription;

  /// The job's launch command — stored with a saved run for reference.
  final String jobCommand;

  /// The machine the job runs on — stored with a saved run so its origin
  /// shows in the Saved benchmarks view.
  final String machineName;

  /// Display label for the endpoint (e.g. `local:8001`).
  final String endpoint;

  /// The real host + port the batch requests are sent to.
  final String host;
  final int port;

  @override
  ConsumerState<BenchmarkView> createState() => _BenchmarkViewState();
}

class _BenchmarkViewState extends ConsumerState<BenchmarkView> {
  late final TextEditingController _prompt;
  late final TextEditingController _batch;
  late final TextEditingController _maxTokens;
  late final TextEditingController _temperature;
  late final TextEditingController _model;
  _BenchView _view = _BenchView.grid;

  @override
  void initState() {
    super.initState();
    // Seed the fields from the (keep-alive) run state rather than hard-coded
    // defaults, so the settings the user last set are restored when they come
    // back to the tab. Edits are written straight back below.
    final run = ref.read(benchmarkControllerProvider(widget.jobId));
    _prompt = TextEditingController(text: run.prompt);
    _batch = TextEditingController(text: '${run.batchSize}');
    _maxTokens = TextEditingController(text: run.maxTokens?.toString() ?? '');
    _temperature =
        TextEditingController(text: run.temperature?.toString() ?? '');
    _model = TextEditingController(text: run.model);
  }

  @override
  void dispose() {
    _prompt.dispose();
    _batch.dispose();
    _maxTokens.dispose();
    _temperature.dispose();
    _model.dispose();
    super.dispose();
  }

  BenchmarkController get _controller =>
      ref.read(benchmarkControllerProvider(widget.jobId).notifier);

  void _send() => _controller.start(host: widget.host, port: widget.port);

  void _saveBenchmark() {
    final run = ref.read(benchmarkControllerProvider(widget.jobId));
    final desc = widget.jobDescription.trim();
    final defaultName =
        desc.isEmpty ? widget.jobName : '${widget.jobName} · $desc';
    showSaveBenchmarkDialog(
      context,
      run: run,
      endpoint: widget.endpoint,
      machineName: widget.machineName,
      command: widget.jobCommand,
      defaultName: defaultName,
    );
  }

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
          maxTokens: _maxTokens,
          temperature: _temperature,
          model: _model,
          running: run.isRunning,
          onSend: _send,
          onCancel: _controller.cancel,
          onExpandPrompt: _editPrompt,
          onPromptChanged: _controller.setPrompt,
          onBatchChanged: (v) {
            final n = int.tryParse(v);
            if (n != null) _controller.setBatchSize(n);
          },
          onMaxTokensChanged: (v) =>
              _controller.setMaxTokens(int.tryParse(v.trim())),
          onTemperatureChanged: (v) =>
              _controller.setTemperature(double.tryParse(v.trim())),
          onModelChanged: _controller.setModel,
        ),
        const SizedBox(height: AppSpacing.lg),
        _AggregateBar(
          run: run,
          onSave: run.requests.isNotEmpty && !run.isRunning
              ? _saveBenchmark
              : null,
          // The grid/charts toggle rides on the right of the bar, past the
          // streaming indicator / Save button.
          trailing: run.requests.isEmpty
              ? null
              : SegmentedControl<_BenchView>(
                  value: _view,
                  onChanged: (v) => setState(() => _view = v),
                  options: const [
                    SegmentOption(
                      value: _BenchView.grid,
                      label: 'Grid',
                      icon: AppIcons.grid,
                    ),
                    SegmentOption(
                      value: _BenchView.charts,
                      label: 'Charts',
                      icon: AppIcons.chart,
                    ),
                  ],
                ),
        ),
        // Truncation callout — some replies were cut off by a token limit
        // rather than finishing, so the numbers describe clipped responses.
        if (!run.isRunning && run.truncatedCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _TruncationNotice(run: run),
        ],
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: run.requests.isEmpty
              ? _EmptyState(endpoint: widget.endpoint)
              : _view == _BenchView.charts
              ? BenchmarkCharts(samples: run.samples)
              : _Grid(
                  run: run,
                  jobId: widget.jobId,
                  host: widget.host,
                  port: widget.port,
                ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.prompt,
    required this.batch,
    required this.maxTokens,
    required this.temperature,
    required this.model,
    required this.running,
    required this.onSend,
    required this.onCancel,
    required this.onExpandPrompt,
    required this.onPromptChanged,
    required this.onBatchChanged,
    required this.onMaxTokensChanged,
    required this.onTemperatureChanged,
    required this.onModelChanged,
  });

  final TextEditingController prompt;
  final TextEditingController batch;
  final TextEditingController maxTokens;
  final TextEditingController temperature;
  final TextEditingController model;
  final bool running;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onExpandPrompt;
  final ValueChanged<String> onPromptChanged;
  final ValueChanged<String> onBatchChanged;
  final ValueChanged<String> onMaxTokensChanged;
  final ValueChanged<String> onTemperatureChanged;
  final ValueChanged<String> onModelChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The prompt gets a full line of its own; the settings live below.
        AppTextField(
          controller: prompt,
          prefix: '>',
          mono: true,
          onChanged: onPromptChanged,
          suffix: AppIconButton(
            icon: AppIcons.fullscreen,
            size: 15,
            padding: const EdgeInsets.all(6),
            onPressed: onExpandPrompt,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _Setting(
              label: 'Batch',
              width: 52,
              controller: batch,
              onChanged: onBatchChanged,
            ),
            const SizedBox(width: AppSpacing.lg),
            // Empty = no cap: the server generates until EOS or its max seqlen.
            _Setting(
              label: 'Max tokens',
              width: 64,
              placeholder: '∞',
              controller: maxTokens,
              onChanged: onMaxTokensChanged,
            ),
            const SizedBox(width: AppSpacing.lg),
            // Empty = the server's default temperature.
            _Setting(
              label: 'Temp',
              width: 60,
              placeholder: 'auto',
              controller: temperature,
              onChanged: onTemperatureChanged,
            ),
            const SizedBox(width: AppSpacing.lg),
            // Takes the row's slack (a model name can be a long path). Empty
            // sends `zml_model` — llmd ignores the name, vLLM requires a real
            // one.
            Expanded(
              child: _Setting(
                label: 'Model',
                placeholder: 'zml_model',
                controller: model,
                onChanged: onModelChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
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
                hoverColor: c.statusFailed,
                padding: const EdgeInsets.all(9),
                onPressed: onCancel,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A labeled setting in the controls row.
class _Setting extends StatelessWidget {
  const _Setting({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.width,
    this.placeholder,
  });

  final String label;

  /// Fixed field width. Null fills the available space — for that the
  /// `_Setting` itself has to be in an [Expanded].
  final double? width;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final field = AppTextField(
      controller: controller,
      mono: true,
      placeholder: placeholder,
      onChanged: onChanged,
    );
    return Row(
      children: [
        Text(label, style: context.text.smallMuted),
        const SizedBox(width: AppSpacing.sm),
        if (width == null)
          Expanded(child: field)
        else
          SizedBox(width: width, child: field),
      ],
    );
  }
}

/// Shown after a run in which replies were cut off by a token limit — either
/// the configured max-tokens cap or the server's max sequence length.
class _TruncationNotice extends StatelessWidget {
  const _TruncationNotice({required this.run});

  final BenchmarkRun run;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = c.statusStarting;
    final total = run.requests.length;
    final message = run.maxTokens == null
        ? '${run.truncatedCount} of $total responses stopped at the '
              'server\'s max sequence length before finishing.'
        : '${run.truncatedCount} of $total responses hit the '
              '${run.maxTokens}-token cap before finishing.';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.warning, size: 14, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.text.small.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AggregateBar extends StatelessWidget {
  const _AggregateBar({required this.run, this.onSave, this.trailing});

  final BenchmarkRun run;

  /// Non-null when the current run can be saved (finished, non-empty).
  final VoidCallback? onSave;

  /// Pinned to the far right of the bar (the grid/charts toggle).
  final Widget? trailing;

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
            label: 'AVG / REQ',
            value: run.averageTokensPerSecond.toStringAsFixed(1),
            unit: 'tok/s',
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
          if (run.isRunning)
            _StreamingPill()
          else if (onSave != null)
            AppButton(
              label: 'Save',
              icon: AppIcons.save,
              onPressed: onSave,
            ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
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
  const _Grid({
    required this.run,
    required this.jobId,
    required this.host,
    required this.port,
  });

  final BenchmarkRun run;
  final String jobId;
  final String host;
  final int port;

  static const double _spacing = AppSpacing.md;
  static const double _minCardWidth = 280;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Drop to a single full-width column when the row can't comfortably
        // hold two cards, or when there's only one request — so cards fill the
        // width instead of sitting cramped or half-empty. Otherwise the dense
        // two-up grid.
        final fits =
            ((constraints.maxWidth + _spacing) / (_minCardWidth + _spacing))
                .floor()
                .clamp(1, 2);
        final columns = fits > run.requests.length
            ? run.requests.length
            : fits;
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: _spacing,
            mainAxisSpacing: _spacing,
            mainAxisExtent: 172,
          ),
          itemCount: run.requests.length,
          itemBuilder: (context, i) {
            final request = run.requests[i];
            return BenchmarkRequestCard(
              request: request,
              onExpand: () =>
                  showBenchmarkFocus(context, jobId, request.index, host, port),
            );
          },
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
