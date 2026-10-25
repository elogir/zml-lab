import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/execution/native_io.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark.dart';
import '../../saved_benchmarks/presentation/save_benchmark_dialog.dart';
import '../../settings/application/settings_controller.dart';
import '../application/benchmark_controller.dart';
import '../domain/result_template.dart';
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
    required this.target,
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

  /// Where the batch requests actually go (URL and key).
  final ChatEndpoint target;

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
    _temperature = TextEditingController(
      text: run.temperature?.toString() ?? '',
    );
    _model = TextEditingController(text: run.model);
    // What the server serves, for the Model field's placeholder.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.detectModels(widget.target),
    );
  }

  @override
  void didUpdateWidget(BenchmarkView old) {
    super.didUpdateWidget(old);
    // Another target: another server, maybe other models.
    if (old.target != widget.target) _controller.detectModels(widget.target);
  }

  /// The Model field's ▾: asks the server again, then lists what it serves.
  Future<List<String>> _loadModels() async {
    await _controller.detectModels(widget.target);
    if (!mounted) return const [];
    return ref.read(benchmarkControllerProvider(widget.jobId)).serverModels ??
        const [];
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

  /// Above this many requests, a hosted API (billed per request) asks first.
  static const _confirmAbove = 16;

  Future<void> _send() async {
    final target = widget.target;
    final batch = ref.read(benchmarkControllerProvider(widget.jobId)).batchSize;
    if (!target.selfHosted && batch > _confirmAbove) {
      final ok = await showConfirmDialog(
        context,
        title: 'Send $batch requests?',
        message:
            '${target.baseUrl.host} is a hosted API — a batch of $batch '
            'requests may be billed per request and per token.',
        confirmLabel: 'Send $batch',
      );
      if (!ok || !mounted) return;
    }
    await _controller.start(endpoint: target);
  }

  void _saveBenchmark() {
    final run = ref.read(benchmarkControllerProvider(widget.jobId));
    final desc = widget.jobDescription.trim();
    final defaultName = desc.isEmpty
        ? widget.jobName
        : '${widget.jobName} · $desc';
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
    final copyTemplate = ref.watch(
      settingsControllerProvider.select((s) => s.benchCopyTemplate),
    );
    final copyText = run.isRunning || run.requests.isEmpty
        ? null
        : renderResult(
            copyTemplate,
            BenchmarkResult.fromRun(
              run,
              machine: widget.machineName,
              endpoint: widget.endpoint,
            ),
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Controls(
          prompt: _prompt,
          batch: _batch,
          maxTokens: _maxTokens,
          temperature: _temperature,
          model: _model,
          serverModels: run.serverModels,
          loadModels: _loadModels,
          ignoreEos: run.ignoreEos,
          onIgnoreEosChanged: _controller.setIgnoreEos,
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
        _AggregateBar(run: run, copyText: copyText),
        if (run.startError case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          _Notice(error, error: true),
        ],
        // Truncation callout — some replies were cut off by a token limit
        // rather than finishing, so the numbers describe clipped responses.
        // Not when ignoring EOS: hitting the cap is the point then.
        if (!run.isRunning && !run.ignoreEos && run.truncatedCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _Notice(_truncationMessage(run)),
        ],
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: run.requests.isEmpty
              ? _EmptyState(endpoint: widget.endpoint)
              : _view == _BenchView.charts
              ? BenchmarkCharts(samples: run.samples, live: run.isRunning)
              : _Grid(run: run, jobId: widget.jobId, target: widget.target),
        ),
        // Nothing has run yet: no view to switch, nothing to save or clear —
        // so the footer stays out of the way entirely.
        if (run.requests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _FooterBar(
            view: _view,
            onView: (v) => setState(() => _view = v),
            onSave: run.isRunning ? null : _saveBenchmark,
            onClear: run.isRunning ? null : _controller.clear,
          ),
        ],
      ],
    );
    // A short window can't fit the controls, stats and a usable grid: below
    // a minimum the whole view scrolls instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxHeight >= _minHeight
          ? content
          : SingleChildScrollView(
              child: SizedBox(height: _minHeight, child: content),
            ),
    );
  }

  static const _minHeight = 560.0;
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.prompt,
    required this.batch,
    required this.maxTokens,
    required this.temperature,
    required this.model,
    required this.serverModels,
    required this.loadModels,
    required this.ignoreEos,
    required this.onIgnoreEosChanged,
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

  /// What the server's `/models` listed (null = not asked yet).
  final List<String>? serverModels;
  final Future<List<String>> Function() loadModels;
  final bool ignoreEos;
  final ValueChanged<bool> onIgnoreEosChanged;
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
    final promptField = AppTextField(
      controller: prompt,
      prefix: '>',
      mono: true,
      onChanged: onPromptChanged,
      suffix: AppIconButton(
        icon: AppIcons.fullscreen,
        size: 14,
        padding: const EdgeInsets.all(2),
        onPressed: onExpandPrompt,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Very wide: the prompt shares the settings' line (one level
        // fewer). Otherwise it gets a line of its own above them.
        final oneRow = constraints.maxWidth >= _promptInlineWidth;
        final wide = constraints.maxWidth >= _oneLineWidth;
        final modelBesideSend = constraints.maxWidth >= _modelLineWidth;
        // Shares of the row: on one line the settings fill it in
        // proportion (Model + Send the biggest, so nothing balloons and
        // no gap trails Send); stacked, the numbers split it equally.
        Widget number(SettingField s, int flex) =>
            Expanded(flex: wide ? flex : 1, child: s);
        final numbers = [
          number(
            SettingField(
              label: 'Batch',
              controller: batch,
              onChanged: onBatchChanged,
              presets: const [
                '1',
                '2',
                '4',
                '8',
                '16',
                '32',
                '64',
                '128',
                '256',
                '512',
                '1024',
              ],
            ),
            2,
          ),
          const SizedBox(width: AppSpacing.md),
          // Empty = no cap: the server generates until EOS or its max
          // seqlen.
          number(
            SettingField(
              label: 'Max tokens',
              placeholder: '∞',
              controller: maxTokens,
              onChanged: onMaxTokensChanged,
            ),
            2,
          ),
          const SizedBox(width: AppSpacing.md),
          // Empty = the server's default temperature.
          number(
            SettingField(
              label: 'Temp',
              placeholder: 'auto',
              controller: temperature,
              onChanged: onTemperatureChanged,
            ),
            2,
          ),
        ];
        // An override: empty sends the server's model when it serves just
        // one, `zml_model` when it lists none (llmd ignores the name; vLLM
        // requires the real one). The ▾ lists what it serves.
        final models = serverModels;
        final modelField = SettingField(
          controller: model,
          placeholder: switch (models) {
            [final only] => '$only (auto)',
            [_, _, ...] => 'pick one of ${models.length} models',
            [] => 'zml_model',
            null => 'from /v1/models',
          },
          loadPresets: loadModels,
          noPresets: 'no models at /v1/models',
          onChanged: onModelChanged,
        );
        // Every reply runs to the token cap: comparable runs.
        final ignoreEosToggle = CheckToggle(
          label: 'Ignore EOS',
          value: ignoreEos,
          onChanged: onIgnoreEosChanged,
        );
        Widget sendButton({required bool stretch}) => RunActions(
          label: 'Send batch',
          icon: AppIcons.send,
          running: running,
          onRun: onSend,
          onStop: onCancel,
          stretch: stretch,
        );
        // [field] with Ignore EOS and Send (or Stop) beside it, at exactly
        // its height.
        Widget withActions(String label, Widget field) => LabeledControl(
          label: label,
          child: FieldWithActions(
            field: field,
            actions: ({required stretch}) => Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: stretch
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.center,
              children: [
                ignoreEosToggle,
                const SizedBox(width: AppSpacing.md),
                sendButton(stretch: stretch),
              ],
            ),
          ),
        );
        final send = Expanded(
          flex: wide ? 8 : 1,
          child: withActions('Model', modelField),
        );
        // Labels sit above their fields, so fields line up and the
        // button aligns with them at the bottom.
        if (oneRow) {
          // Settings first (Batch at the left edge, under Target), then the
          // prompt right before Send.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ...numbers,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 4,
                child: LabeledControl(label: 'Model', child: modelField),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 8, child: withActions('Prompt', promptField)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            promptField,
            const SizedBox(height: AppSpacing.sm),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ...numbers,
                  const SizedBox(width: AppSpacing.md),
                  send,
                ],
              )
            else ...[
              Row(children: numbers),
              const SizedBox(height: AppSpacing.sm),
              if (modelBesideSend)
                Row(children: [send])
              else ...[
                // Narrowest: the model gets the whole line, Ignore EOS and
                // Send one under it.
                LabeledControl(label: 'Model', child: modelField),
                const SizedBox(height: AppSpacing.sm),
                Stack(
                  children: [
                    // A field's height…
                    const Visibility.maintain(
                      visible: false,
                      child: AppTextField(mono: true),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      child: Center(child: ignoreEosToggle),
                    ),
                    // …Send at the right, filling it.
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: sendButton(stretch: true),
                    ),
                  ],
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  // The breakpoints keep the model field ~200 px wide or more: room for a
  // model name, not just its first letters.

  /// From this width the prompt joins the settings' row.
  static const _promptInlineWidth = 1150.0;

  /// Below this the model and Send get a line of their own, under the
  /// numbers.
  static const _oneLineWidth = 880.0;

  /// Below this the model gets a line to itself, Ignore EOS and Send one
  /// under it.
  static const _modelLineWidth = 480.0;
}

/// After a run in which replies were cut off by a token limit — either the
/// configured max-tokens cap or the server's max sequence length.
String _truncationMessage(BenchmarkRun run) {
  final total = run.requests.length;
  return run.maxTokens == null
      ? '${run.truncatedCount} of $total responses stopped at the '
            'server\'s max sequence length before finishing.'
      : '${run.truncatedCount} of $total responses hit the '
            '${run.maxTokens}-token cap before finishing.';
}

/// A callout above the results: a warning (replies cut off), or an [error]
/// (why a Send didn't start).
class _Notice extends StatelessWidget {
  const _Notice(this.message, {this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = error ? c.statusFailed : c.statusStarting;
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

/// The run's headline numbers, with the live indicator while it streams and
/// "Copy results" once it settles (the numbers it copies are right here).
/// Save, Clear and the view switcher live in the [_FooterBar].
class _AggregateBar extends StatelessWidget {
  const _AggregateBar({required this.run, this.copyText});

  final BenchmarkRun run;

  /// The run rendered through the user's copy template; null hides the button.
  final String? copyText;

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
          // A grid: when the terminal leaves the tools narrow, the stats wrap
          // into aligned columns rather than hiding off the right edge.
          Expanded(
            child: StatGrid(
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
                _Stat(
                  label: 'AVG / REQ',
                  value: run.averageTokensPerSecond.toStringAsFixed(1),
                  unit: 'tok/s',
                ),
                _Stat(
                  label: 'COMPLETED',
                  value: '${run.completed}',
                  // Denominator is the batch actually in flight, not the (editable)
                  // batch-size setting — so tweaking the field for the next run
                  // doesn't skew the current run's count.
                  unit:
                      '/${run.requests.isEmpty ? run.batchSize : run.requests.length}',
                ),
                _Stat(
                  label: 'MEDIAN TTFT',
                  value: '${run.medianTtftMs}',
                  unit: 'ms',
                ),
                _Stat(
                  label: 'ELAPSED',
                  value: (run.elapsed.inMilliseconds / 1000).toStringAsFixed(1),
                  unit: 's',
                ),
              ],
            ),
          ),
          if (run.isRunning) ...[
            const SizedBox(width: AppSpacing.lg),
            _StreamingPill(),
          ] else if (copyText != null) ...[
            const SizedBox(width: AppSpacing.lg),
            CopyButton(text: copyText!, label: 'Copy results'),
          ],
        ],
      ),
    );
  }
}

/// Footer under the results: the view switcher on the left, the run's actions
/// on the right. Bare — no panel — so it costs a row of buttons in height and
/// nothing else.
class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.view,
    required this.onView,
    this.onSave,
    this.onClear,
  });

  final _BenchView view;
  final ValueChanged<_BenchView> onView;

  /// Null while the batch is still in flight — a run is saved once it settles.
  final VoidCallback? onSave;

  /// Null while the batch is still in flight (Cancel covers that case).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SegmentedControl<_BenchView>(
          value: view,
          onChanged: onView,
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
        const Spacer(),
        // Ghost, and left of Save: discarding the run is the secondary action
        // next to keeping it.
        if (onClear != null)
          AppButton(
            label: 'Clear',
            icon: AppIcons.delete,
            variant: AppButtonVariant.ghost,
            onPressed: onClear,
          ),
        if (onSave != null) ...[
          const SizedBox(width: AppSpacing.sm),
          AppButton(label: 'Save', icon: AppIcons.save, onPressed: onSave),
        ],
      ],
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
          mainAxisSize: MainAxisSize.min,
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
  const _Grid({required this.run, required this.jobId, required this.target});

  final BenchmarkRun run;
  final String jobId;
  final ChatEndpoint target;

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
        final columns = fits > run.requests.length ? run.requests.length : fits;
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
            return _WatchedText(
              jobId: jobId,
              index: request.index,
              child: BenchmarkRequestCard(
                request: request,
                onExpand: () =>
                    showBenchmarkFocus(context, jobId, request.index, target),
              ),
            );
          },
        );
      },
    );
  }
}

/// Tells the controller request [index]'s card is on screen while it's
/// mounted, so a big batch keeps that card's text live (see
/// [BenchmarkController.watchText]). The grid builds lazily, so mounted ≈
/// visible.
class _WatchedText extends ConsumerStatefulWidget {
  const _WatchedText({
    required this.jobId,
    required this.index,
    required this.child,
  });

  final String jobId;
  final int index;
  final Widget child;

  @override
  ConsumerState<_WatchedText> createState() => _WatchedTextState();
}

class _WatchedTextState extends ConsumerState<_WatchedText> {
  // Captured up front: dispose must not read through `ref`.
  late final BenchmarkController _controller = ref.read(
    benchmarkControllerProvider(widget.jobId).notifier,
  );

  @override
  void initState() {
    super.initState();
    _controller.watchText(widget.index);
  }

  @override
  void didUpdateWidget(_WatchedText old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _controller
        ..unwatchText(old.index)
        ..watchText(widget.index);
    }
  }

  @override
  void dispose() {
    _controller.unwatchText(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.endpoint});

  final String endpoint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Scrolls and wraps rather than overflowing a short or narrow window.
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.benchmark, size: 26, color: c.textFaint),
            const SizedBox(height: AppSpacing.md),
            Text('No benchmark running', style: context.text.bodySecondary),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                text: 'Set a batch size and send requests to ',
                style: context.text.smallMuted,
                children: [
                  TextSpan(text: endpoint, style: context.text.monoSmall),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
