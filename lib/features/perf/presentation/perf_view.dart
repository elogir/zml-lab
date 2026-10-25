import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/perf_report.dart';
import '../../../core/shell/app_fullscreen.dart';
import '../application/perf_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../application/sharegpt_dataset.dart';
import '../domain/bench_runner.dart';
import '../domain/run_recorder_types.dart';
import '../domain/sharegpt.dart';
import 'export_run_dialog.dart';
import 'perf_charts.dart';
import 'perf_report_view.dart';
import 'save_perf_report_dialog.dart';
import 'sharegpt_download_card.dart';

/// The Benchmark tab's Perf tool: configure and run the load benchmark
/// against the target endpoint, watch it live, then read, save or export the
/// report.
class PerfView extends ConsumerStatefulWidget {
  const PerfView({
    super.key,
    required this.jobId,
    required this.jobName,
    required this.jobDescription,
    required this.machineName,
    required this.host,
    required this.port,
    this.machine,
    this.hardware,
  });

  final String jobId;
  final String jobName;
  final String jobDescription;
  final String machineName;
  final String host;
  final int port;

  /// The saved machine benchmarked, if one was picked, and its hardware —
  /// recorded in the run's meta.json.
  final String? machine;
  final String? hardware;

  @override
  ConsumerState<PerfView> createState() => _PerfViewState();
}

class _PerfViewState extends ConsumerState<PerfView> {
  late final TextEditingController _duration;
  late final TextEditingController _concurrency;
  late final TextEditingController _maxTokens;
  late final TextEditingController _model;
  String? _preflightProblem;
  String? _exportedTo;

  /// Re-checks the dataset when the app comes back to the front — it may
  /// have been deleted or moved in Finder meanwhile.
  late final AppLifecycleListener _lifecycle;

  PerfController get _controller =>
      ref.read(perfControllerProvider(widget.jobId).notifier);

  void _refreshDataset() =>
      ref.read(shareGptDatasetProvider.notifier).refresh();

  @override
  void initState() {
    super.initState();
    final run = ref.read(perfControllerProvider(widget.jobId));
    _duration = TextEditingController(text: '${run.params.durationSeconds}');
    _concurrency = TextEditingController(text: '${run.params.concurrency}');
    _maxTokens = TextEditingController(
      text: run.params.maxCompletionTokens?.toString() ?? '',
    );
    _model = TextEditingController(text: run.params.model);
    // The dataset has its own card (with a download); this is the rest.
    _preflightProblem = _controller.libraryProblem();
    _lifecycle = AppLifecycleListener(onResume: _refreshDataset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Every visit looks again (the dataset state outlives the tab).
      _refreshDataset();
      _controller.detectModels(host: widget.host, port: widget.port);
    });
  }

  @override
  void didUpdateWidget(PerfView old) {
    super.didUpdateWidget(old);
    // Another target: another server, maybe other models.
    if (old.host != widget.host || old.port != widget.port) {
      _controller.detectModels(host: widget.host, port: widget.port);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _duration.dispose();
    _concurrency.dispose();
    _maxTokens.dispose();
    _model.dispose();
    super.dispose();
  }

  void _patchParams(PerfParams Function(PerfParams) patch) {
    final run = ref.read(perfControllerProvider(widget.jobId));
    _controller.setParams(patch(run.params));
  }

  Future<void> _start() async {
    setState(() => _exportedTo = null);
    await _controller.start(
      host: widget.host,
      port: widget.port,
      jobName: widget.jobName,
      machineName: widget.machineName,
      machine: widget.machine,
      hardware: widget.hardware,
    );
  }

  static String _folderOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash <= 0 ? path : path.substring(0, slash);
  }

  /// Picks where ShareGPT goes (a Finder folder dialog) and saves it as the
  /// dataset path in Settings — a copy already in that folder is used as is.
  Future<void> _chooseFolder(DatasetState dataset) async {
    final current = expandUserPath(_folderOf(dataset.path));
    final dir = await getDirectoryPath(
      initialDirectory: directoryExists(current) ? current : null,
      confirmButtonText: 'Save here',
    );
    if (dir == null || !mounted) return;
    ref
        .read(settingsControllerProvider.notifier)
        .setPerfDatasetPath('$dir/${ShareGpt.fileName}');
  }

  Future<void> _export(String runFile) async {
    final dest = await showExportRunDialog(context, runFile: runFile);
    if (dest == null) return;
    await revealInFinder(dest);
    if (mounted) setState(() => _exportedTo = dest);
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(perfControllerProvider(widget.jobId));
    final report = run.report;
    final fullscreen =
        ref.watch(appFullscreenProvider) == FullscreenSurface.perf;
    final dataset = ref.watch(shareGptDatasetProvider);
    final datasetReady = dataset.phase == DatasetPhase.ready;

    return Padding(
      // In fullscreen the Benchmark screen drops its own padding; this view
      // re-adds breathing room.
      padding: fullscreen
          ? const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            )
          : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Controls(
            run: run,
            duration: _duration,
            concurrency: _concurrency,
            maxTokens: _maxTokens,
            model: _model,
            loadModels: () async {
              await _controller.detectModels(
                host: widget.host,
                port: widget.port,
              );
              return ref
                      .read(perfControllerProvider(widget.jobId))
                      .serverModels ??
                  const [];
            },
            fullscreen: fullscreen,
            onToggleFullscreen: () => ref
                .read(appFullscreenProvider.notifier)
                .toggle(FullscreenSurface.perf),
            onPatch: _patchParams,
            // No dataset, nothing to replay: the card below gets it first.
            onRun: datasetReady ? _start : null,
            onCancel: _controller.cancel,
          ),
          if (_preflightProblem != null && !run.phase.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            _PreflightWarning(problem: _preflightProblem!),
          ],
          const SizedBox(height: AppSpacing.md),
          if (run.phase != PerfPhase.idle) ...[
            _StatusBar(
              run: run,
              saved: run.saved,
              exportedTo: _exportedTo,
              copyText: run.phase == PerfPhase.done && report != null
                  ? _controller.copyText
                  : null,
              onSave:
                  run.phase == PerfPhase.done && report != null && !run.saved
                  ? () => showSavePerfReportDialog(
                      context,
                      jobId: widget.jobId,
                      defaultName: widget.jobDescription.trim().isEmpty
                          ? widget.jobName
                          : '${widget.jobName} · ${widget.jobDescription.trim()}',
                    )
                  : null,
              // Once the recording is written (a moment after the run ends).
              onExport: run.phase == PerfPhase.done && run.runFile != null
                  ? () => _export(run.runFile!)
                  : null,
              onDiscard:
                  run.phase == PerfPhase.done || run.phase == PerfPhase.failed
                  ? () {
                      setState(() => _exportedTo = null);
                      _controller.discard();
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Expanded(child: _body(run, dataset)),
        ],
      ),
    );
  }

  Widget _body(PerfRun run, DatasetState dataset) {
    switch (run.phase) {
      case PerfPhase.idle:
        return switch (dataset.phase) {
          DatasetPhase.ready => _EmptyState(problem: _preflightProblem),
          DatasetPhase.checking => const SizedBox.shrink(),
          _ => Center(
            child: SingleChildScrollView(
              child: ShareGptDownload(
                state: dataset,
                folder: abbreviateUserPath(
                  expandUserPath(_folderOf(dataset.path)),
                ),
                onDownload: ref.read(shareGptDatasetProvider.notifier).download,
                onCancel: ref.read(shareGptDatasetProvider.notifier).cancel,
                onChooseFolder: kIsWeb ? null : () => _chooseFolder(dataset),
              ),
            ),
          ),
        };
      case PerfPhase.preparing:
      case PerfPhase.running:
      case PerfPhase.stopping:
        return SingleChildScrollView(
          child: PerfLiveCharts(
            series: run.series,
            // Stopping: the last samples are in — let the line settle.
            live: run.phase != PerfPhase.stopping,
          ),
        );
      case PerfPhase.failed:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.warning,
                size: 20,
                color: context.colors.statusFailed,
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  run.message ?? 'the benchmarker failed',
                  style: context.text.smallMuted,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      case PerfPhase.done:
        final report = run.report;
        if (report == null) return const SizedBox.shrink();
        return PerfReportView(report: report);
    }
  }
}

/// The run parameter form + Run/Cancel.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.run,
    required this.duration,
    required this.concurrency,
    required this.maxTokens,
    required this.model,
    required this.loadModels,
    required this.fullscreen,
    required this.onToggleFullscreen,
    required this.onPatch,
    required this.onRun,
    required this.onCancel,
  });

  final PerfRun run;
  final TextEditingController duration;
  final TextEditingController concurrency;
  final TextEditingController maxTokens;
  final TextEditingController model;

  /// The target's `/v1/models`, for the Model field's ▾.
  final Future<List<String>> Function() loadModels;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final void Function(PerfParams Function(PerfParams)) onPatch;
  final VoidCallback? onRun;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final active = run.phase.isActive;
    int? positive(String v) => switch (int.tryParse(v.trim())) {
      final n? when n > 0 => n,
      _ => null,
    };
    final durationField = SettingField(
      label: 'Duration (s)',
      controller: duration,
      presets: const ['10', '30', '60', '120', '300', '600'],
      onChanged: (v) {
        if (positive(v) case final n?) {
          onPatch((p) => p.copyWith(durationSeconds: n));
        }
      },
    );
    final concurrencyField = SettingField(
      label: 'Concurrency',
      controller: concurrency,
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
      onChanged: (v) {
        if (positive(v) case final n?) {
          onPatch((p) => p.copyWith(concurrency: n));
        }
      },
    );
    // Empty = no cap: the server stops at EOS (or its max sequence length).
    // Shared with the Settings default.
    final maxTokensField = SettingField(
      label: 'Max tokens',
      controller: maxTokens,
      placeholder: '∞',
      presets: const ['64', '128', '256', '512', '1024', '2048', '4096'],
      onChanged: (v) =>
          onPatch((p) => p.copyWith(maxCompletionTokens: positive(v))),
    );
    // Segmented choices at a field's height, as wide as their labels.
    Widget choice<T>(
      String label,
      T value,
      List<SegmentOption<T>> options,
      ValueChanged<T> onChanged,
    ) => IntrinsicWidth(
      child: LabeledControl(
        label: label,
        child: FieldHeight(
          child: SegmentedControl<T>(
            fill: true,
            value: value,
            options: options,
            onChanged: onChanged,
          ),
        ),
      ),
    );
    final prompts = choice('Prompts', run.params.sequenceType, const [
      SegmentOption(value: 'long', label: 'Long'),
      SegmentOption(value: 'short', label: 'Short'),
    ], (v) => onPatch((p) => p.copyWith(sequenceType: v)));
    final turns = choice('Turns', run.params.mode, const [
      SegmentOption(value: 'all', label: 'All'),
      SegmentOption(value: 'first', label: 'First'),
    ], (v) => onPatch((p) => p.copyWith(mode: v)));
    final warmup = CheckToggle(
      label: 'Warm-up',
      value: run.params.warmup,
      onChanged: (v) => onPatch((p) => p.copyWith(warmup: v)),
    );
    // Every reply runs to the token cap: comparable runs.
    final ignoreEos = CheckToggle(
      label: 'Ignore EOS',
      value: run.params.ignoreEos,
      onChanged: (v) => onPatch((p) => p.copyWith(ignoreEos: v)),
    );
    final toggles = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        warmup,
        const SizedBox(width: AppSpacing.md),
        ignoreEos,
      ],
    );
    // An override, never filled for you: empty, a run uses the server's
    // model when it serves just one (vLLM needs the real name; llmd ignores
    // it). The ▾ lists what /v1/models serves, filling in a lone one.
    final models = run.serverModels;
    final modelField = SettingField(
      controller: model,
      placeholder: switch (models) {
        [final only] => '$only (auto)',
        [_, _, ...] => 'pick one of ${models.length} models',
        _ => 'from /v1/models',
      },
      loadPresets: loadModels,
      noPresets: 'no models at /v1/models',
      onChanged: (v) => onPatch((p) => p.copyWith(model: v.trim())),
    );
    // The model field with the run controls beside it at its height:
    // [withWarmup] puts the toggles first (when they aren't elsewhere).
    Widget modelAndActions({required bool withWarmup}) => LabeledControl(
      label: 'Model',
      child: FieldWithActions(
        field: modelField,
        actions: ({required stretch}) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: stretch
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.center,
          children: [
            if (withWarmup) ...[toggles, const SizedBox(width: AppSpacing.md)],
            RunActions(
              label: 'Run benchmark',
              icon: AppIcons.play,
              running: active,
              onRun: active ? null : onRun,
              onStop: onCancel,
              stretch: stretch,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Same fullscreen as the terminal: sidebar, header and actions
            // panel all collapse away.
            Center(
              child: AppIconButton(
                icon: fullscreen
                    ? AppIcons.exitFullscreen
                    : AppIcons.fullscreen,
                size: 15,
                padding: const EdgeInsets.all(9),
                onPressed: onToggleFullscreen,
              ),
            ),
          ],
        ),
      ),
    );
    const gap = SizedBox(width: AppSpacing.md);

    // Labels sit above their fields, so a row's fields line up at the
    // bottom and the run controls align with them.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= _oneLineWidth) {
          // Everything on one line: the numbers get a fixed width (enough
          // for 4 digits), the model all the rest.
          Widget number(Widget field) => SizedBox(width: 110, child: field);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              number(durationField),
              gap,
              number(concurrencyField),
              gap,
              number(maxTokensField),
              gap,
              prompts,
              gap,
              turns,
              gap,
              Expanded(child: modelAndActions(withWarmup: true)),
            ],
          );
        }
        final numbers = [
          Expanded(child: durationField),
          gap,
          Expanded(child: concurrencyField),
          gap,
          Expanded(child: maxTokensField),
        ];
        if (width >= _twoLineWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [...numbers, gap, prompts, gap, turns],
              ),
              const SizedBox(height: AppSpacing.sm),
              modelAndActions(withWarmup: true),
            ],
          );
        }
        // Narrow (terminal open): the choices and the warm-up toggle get a
        // line of their own so the model field keeps some room — narrower
        // still, the model gets a whole line, the run controls one under it.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: numbers),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                prompts,
                turns,
                FieldHeight(child: toggles),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (width >= _modelLineWidth)
              modelAndActions(withWarmup: false)
            else ...[
              LabeledControl(label: 'Model', child: modelField),
              const SizedBox(height: AppSpacing.sm),
              Stack(
                children: [
                  // A field's height…
                  const Visibility.maintain(
                    visible: false,
                    child: AppTextField(mono: true),
                  ),
                  // …filled by Run, the whole line wide (beside fullscreen).
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: RunActions(
                            label: 'Run benchmark',
                            icon: AppIcons.play,
                            running: active,
                            onRun: active ? null : onRun,
                            onStop: onCancel,
                            stretch: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Center(
                          child: AppIconButton(
                            icon: fullscreen
                                ? AppIcons.exitFullscreen
                                : AppIcons.fullscreen,
                            size: 15,
                            padding: const EdgeInsets.all(9),
                            onPressed: onToggleFullscreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // The breakpoints keep the model field ~200 px wide or more: room for a
  // model name, not just its first letters.

  /// From this width everything fits on one line.
  static const _oneLineWidth = 1260.0;

  /// Below this the run controls get their own line (and below
  /// [_twoLineWidth], the choices too).
  static const _twoLineWidth = 650.0;

  /// Below this the model field gets a line to itself, the run controls
  /// one under it: beside them it would be too cramped for a model name.
  static const _modelLineWidth = 460.0;
}

/// Live stats while running; save/export actions once done.
class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.run,
    required this.saved,
    required this.exportedTo,
    required this.copyText,
    required this.onSave,
    required this.onExport,
    required this.onDiscard,
  });

  final PerfRun run;
  final bool saved;
  final String? exportedTo;

  /// Builds the text for the copy button (async — may shell out to duckdb).
  /// Null until there's a finished report to copy.
  final Future<String> Function()? copyText;
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showStats =
        run.phase == PerfPhase.running || run.phase == PerfPhase.stopping;
    final status = showStats
        ? Wrap(
            spacing: AppSpacing.xxl,
            runSpacing: AppSpacing.md,
            children: [
              _Stat(
                label: 'TOK/S',
                value: run.liveTps.toStringAsFixed(1),
                valueColor: c.statusRunning,
              ),
              _Stat(label: 'EVENTS', value: '${run.events}'),
              _Stat(label: 'REQUESTS', value: '${run.requests}'),
              _Stat(label: 'ACTIVE', value: '${run.active}'),
              _Stat(
                label: 'ERRORS',
                value: '${run.errors}',
                valueColor: run.errors > 0 ? c.statusFailed : null,
              ),
              _Stat(
                label: 'ELAPSED',
                value:
                    '${run.elapsed.inSeconds}s / '
                    '${run.params.durationSeconds}s',
              ),
              // zml-smi's latest sample, every chip together.
              if (_chipUtil(run.liveChips) case final util?)
                _Stat(label: 'CHIP UTIL', value: '$util%'),
              if (_chipPower(run.liveChips) case final watts?)
                _Stat(label: 'POWER', value: '$watts W'),
            ],
          )
        : run.phase == PerfPhase.done
        ? Row(
            children: [
              Icon(AppIcons.check, size: 14, color: c.statusRunning),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  run.message ?? 'run complete',
                  style: context.text.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (exportedTo != null) ...[
                const SizedBox(width: AppSpacing.lg),
                Flexible(
                  child: Text(
                    exportedTo!,
                    style: context.text.monoSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          )
        : Row(
            children: [
              const _ActivityPill(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  run.message ?? '…',
                  style: context.text.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    final actions = [
      if (run.phase == PerfPhase.done) ...[
        if (saved)
          Text('saved', style: context.text.smallMuted)
        else if (onSave != null)
          AppButton(
            label: 'Save report',
            icon: AppIcons.save,
            variant: AppButtonVariant.primary,
            dense: true,
            onPressed: onSave,
          ),
        if (copyText != null)
          AsyncCopyButton(textBuilder: copyText!, label: 'Copy results'),
        if (onExport != null)
          AppButton(
            label: 'Export run',
            icon: AppIcons.download,
            dense: true,
            onPressed: onExport,
          ),
        if (onDiscard != null)
          AppButton(
            label: 'Discard',
            variant: AppButtonVariant.ghost,
            dense: true,
            onPressed: onDiscard,
          ),
      ],
      if (run.phase == PerfPhase.failed && onDiscard != null)
        AppButton(
          label: 'Dismiss',
          variant: AppButtonVariant.ghost,
          dense: true,
          onPressed: onDiscard,
        ),
    ];
    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow (terminal open): the buttons get a line under the status
          // instead of squeezing it to nothing.
          if (actions.length > 1 && constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: status),
              for (final a in actions) ...[
                const SizedBox(width: AppSpacing.sm),
                a,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Average utilization over the chips that report it.
int? _chipUtil(List<ChipReading> chips) {
  final utils = [for (final c in chips) ?c.utilPercent];
  if (utils.isEmpty) return null;
  return (utils.fold(0, (a, b) => a + b) / utils.length).round();
}

/// Power drawn by the chips that report it, together.
int? _chipPower(List<ChipReading> chips) {
  final watts = [for (final c in chips) ?c.powerW];
  if (watts.isEmpty) return null;
  return watts.fold(0.0, (a, b) => a + b).round();
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.columnHeader),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.text.mono.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Amber pulse dot + nothing else — the message next to it carries the news.
class _ActivityPill extends StatelessWidget {
  const _ActivityPill();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: c.statusStarting,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PreflightWarning extends StatelessWidget {
  const _PreflightWarning({required this.problem});

  final String problem;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(AppIcons.warning, size: 12, color: c.statusStarting),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            problem,
            style: context.text.smallMuted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.problem});

  final String? problem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.perf, size: 22, color: context.colors.textFaint),
            const SizedBox(height: AppSpacing.md),
            Text('Load benchmark', style: context.text.bodyStrong),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Replays ShareGPT conversations against this endpoint at a '
              'fixed concurrency, then reports TTFT, inter-token latency '
              'and throughput percentiles.',
              style: context.text.smallMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
