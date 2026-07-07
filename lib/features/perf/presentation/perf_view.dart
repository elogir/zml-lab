import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/perf_report.dart';
import '../../job_detail/application/terminal_fullscreen.dart';
import '../application/perf_controller.dart';
import '../domain/bench_runner.dart';
import '../domain/report_text.dart';
import 'perf_charts.dart';
import 'perf_report_view.dart';
import 'save_perf_report_dialog.dart';

/// The job detail's Perf tab: configure and run the monorepo's benchmarker
/// (tools/benchmark) against this job's endpoint, watch it live, then read,
/// save or export the report.
class PerfView extends ConsumerStatefulWidget {
  const PerfView({
    super.key,
    required this.jobId,
    required this.jobName,
    required this.jobDescription,
    required this.jobCommand,
    required this.machineName,
    required this.host,
    required this.port,
  });

  final String jobId;
  final String jobName;
  final String jobDescription;
  final String jobCommand;
  final String machineName;
  final String host;
  final int port;

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

  PerfController get _controller =>
      ref.read(perfControllerProvider(widget.jobId).notifier);

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.prefillModel(host: widget.host, port: widget.port);
      if (!mounted) return;
      final model = ref.read(perfControllerProvider(widget.jobId)).params.model;
      if (_model.text.isEmpty && model.isNotEmpty) _model.text = model;
      final problem = await _controller.preflight();
      if (mounted) setState(() => _preflightProblem = problem);
    });
  }

  @override
  void dispose() {
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
      jobCommand: widget.jobCommand,
      machineName: widget.machineName,
    );
  }

  Future<void> _export(PerfReport report) async {
    final stamp = report.createdAt;
    final name =
        '${report.name} '
        '${stamp.year}-${stamp.month.toString().padLeft(2, '0')}-'
        '${stamp.day.toString().padLeft(2, '0')}';
    try {
      final dest = await exportTextFile(
        content: perfReportCsv(report),
        name: name,
      );
      await revealInFinder(dest);
      if (mounted) setState(() => _exportedTo = dest);
    } catch (e) {
      if (mounted) setState(() => _exportedTo = 'export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(perfControllerProvider(widget.jobId));
    final report = run.report;
    final fullscreen = ref.watch(terminalFullscreenProvider);

    return Padding(
      // In fullscreen the detail screen drops its own padding (the terminal
      // wants edge-to-edge); this view re-adds breathing room.
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
          fullscreen: fullscreen,
          onToggleFullscreen: () =>
              ref.read(terminalFullscreenProvider.notifier).toggle(),
          onPatch: _patchParams,
          onRun: _start,
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
            onSave: run.phase == PerfPhase.done && report != null && !run.saved
                ? () => showSavePerfReportDialog(
                    context,
                    jobId: widget.jobId,
                    defaultName: widget.jobDescription.trim().isEmpty
                        ? widget.jobName
                        : '${widget.jobName} · ${widget.jobDescription.trim()}',
                  )
                : null,
            onExport: run.phase == PerfPhase.done && report != null
                ? () => _export(report)
                : null,
            onDiscard: run.phase == PerfPhase.done || run.phase == PerfPhase.failed
                ? () {
                    setState(() => _exportedTo = null);
                    _controller.discard();
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Expanded(child: _body(run)),
      ],
      ),
    );
  }

  Widget _body(PerfRun run) {
    switch (run.phase) {
      case PerfPhase.idle:
        return _EmptyState(problem: _preflightProblem);
      case PerfPhase.preparing:
      case PerfPhase.running:
      case PerfPhase.stopping:
        return SingleChildScrollView(
          child: PerfLiveCharts(series: run.series),
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
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final void Function(PerfParams Function(PerfParams)) onPatch;
  final VoidCallback onRun;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = run.phase.isActive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wrap, not Row: with the sidebar and actions panel both expanded the
        // tab can get narrow, and the fields flow onto a second line.
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _Setting(
              label: 'Duration s',
              width: 64,
              child: AppTextField(
                controller: duration,
                mono: true,
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  if (n != null && n > 0) {
                    onPatch((p) => p.copyWith(durationSeconds: n));
                  }
                },
              ),
            ),
            _Setting(
              label: 'Concurrency',
              width: 76,
              child: AppTextField(
                controller: concurrency,
                mono: true,
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  if (n != null && n > 0) {
                    onPatch((p) => p.copyWith(concurrency: n));
                  }
                },
              ),
            ),
            _Setting(
              label: 'Max tokens',
              width: 96,
              child: AppTextField(
                controller: maxTokens,
                mono: true,
                // Empty = don't pass --max-completion-tokens (the benchmarker
                // uses its own default). Shared with the Settings default.
                placeholder: 'default',
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  onPatch(
                    (p) => p.copyWith(
                      maxCompletionTokens: n != null && n > 0 ? n : null,
                    ),
                  );
                },
              ),
            ),
            _Setting(
              label: 'Prompts',
              child: SegmentedControl<String>(
                value: run.params.sequenceType,
                onChanged: (v) => onPatch((p) => p.copyWith(sequenceType: v)),
                options: const [
                  SegmentOption(value: 'long', label: 'Long'),
                  SegmentOption(value: 'short', label: 'Short'),
                ],
              ),
            ),
            _Setting(
              label: 'Turns',
              child: SegmentedControl<String>(
                value: run.params.mode,
                onChanged: (v) => onPatch((p) => p.copyWith(mode: v)),
                options: const [
                  SegmentOption(value: 'all', label: 'All'),
                  SegmentOption(value: 'first', label: 'First'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _Setting(
                label: 'Model (vLLM needs the real name; llmd ignores it)',
                child: AppTextField(
                  controller: model,
                  mono: true,
                  placeholder: 'from /v1/models',
                  onChanged: (v) => onPatch((p) => p.copyWith(model: v.trim())),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            _WarmupToggle(
              value: run.params.warmup,
              onChanged: (v) => onPatch((p) => p.copyWith(warmup: v)),
            ),
            const SizedBox(width: AppSpacing.lg),
            if (active)
              AppIconButton(
                icon: AppIcons.kill,
                color: c.statusFailed,
                hoverColor: c.statusFailed,
                padding: const EdgeInsets.all(8),
                onPressed: onCancel,
              )
            else
              AppButton(
                label: 'Run benchmark',
                icon: AppIcons.play,
                variant: AppButtonVariant.primary,
                onPressed: onRun,
              ),
            const SizedBox(width: AppSpacing.sm),
            // Same fullscreen as the terminal: sidebar, header and actions
            // panel all collapse away.
            AppIconButton(
              icon: fullscreen ? AppIcons.exitFullscreen : AppIcons.fullscreen,
              size: 15,
              padding: const EdgeInsets.all(9),
              onPressed: onToggleFullscreen,
            ),
          ],
        ),
      ],
    );
  }
}

class _Setting extends StatelessWidget {
  const _Setting({required this.label, required this.child, this.width});

  final String label;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.smallMuted),
        const SizedBox(height: 6),
        child,
      ],
    );
    return width == null ? column : SizedBox(width: width, child: column);
  }
}

/// Small check toggle for the warm-up request.
class _WarmupToggle extends StatelessWidget {
  const _WarmupToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: () => onChanged(!value),
      builder: (context, hovered) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: value ? c.accent : const Color(0x00000000),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value
                      ? c.accent
                      : (hovered ? c.borderStrong : c.border),
                ),
              ),
              child: value
                  ? const Icon(
                      AppIcons.check,
                      size: 11,
                      color: Color(0xFFFFFFFF),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('warm-up request first', style: context.text.small),
          ],
        ),
      ),
    );
  }
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
    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: showStats
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
                    ],
                  )
                : run.phase == PerfPhase.done
                ? Row(
                    children: [
                      Icon(AppIcons.check, size: 14, color: c.statusRunning),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        run.message ?? 'run complete',
                        style: context.text.small,
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
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
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
            if (copyText != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AsyncCopyButton(textBuilder: copyText!, label: 'Copy results'),
            ],
            if (onExport != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Export CSV',
                icon: AppIcons.download,
                dense: true,
                onPressed: onExport,
              ),
            ],
            if (onDiscard != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Discard',
                variant: AppButtonVariant.ghost,
                dense: true,
                onPressed: onDiscard,
              ),
            ],
          ],
          if (run.phase == PerfPhase.failed && onDiscard != null)
            AppButton(
              label: 'Dismiss',
              variant: AppButtonVariant.ghost,
              dense: true,
              onPressed: onDiscard,
            ),
        ],
      ),
    );
  }
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
            '$problem — paths are configurable in Settings',
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
              'Runs the monorepo benchmarker against this endpoint with '
              'ShareGPT prompts at fixed concurrency, then reports TTFT, '
              'inter-token latency and throughput percentiles.',
              style: context.text.smallMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
