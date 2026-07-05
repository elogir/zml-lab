import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/execution/job_executor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/job.dart';
import '../../../models/machine.dart';
import '../../benchmark/presentation/benchmark_view.dart';
import '../../machines/application/machines_providers.dart';
import '../application/job_detail_providers.dart';
import '../application/profiler_controller.dart';
import '../application/terminal_fullscreen.dart';
import 'actions_panel.dart';
import 'endpoint_test_dialog.dart';
import 'job_terminal.dart';

enum _DetailMode { terminal, benchmark }

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  _DetailMode _mode = _DetailMode.terminal;
  bool _actionsCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobStreamProvider(widget.jobId));
    final job = jobAsync.value;

    if (job == null) {
      return Center(
        child: Text(
          jobAsync.isLoading ? 'Loading…' : 'Job not found',
          style: context.text.smallMuted,
        ),
      );
    }

    final machine = ref.watch(machineMapProvider)[job.machineId];
    final endpoint = '${machine?.name ?? job.machineId}:${job.port}';
    // The real host to reach the server on: loopback for a local job, else the
    // machine's address.
    final host = (machine != null && !machine.isLocal)
        ? machine.address
        : '127.0.0.1';
    final profiler = ref.watch(profilerControllerProvider(job.id));
    final fullscreen = ref.watch(terminalFullscreenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header slot is kept (as an empty box in fullscreen) rather than
        // removed, so the terminal below stays at a stable index and isn't
        // rebuilt — its live sessions survive the toggle.
        if (fullscreen)
          const SizedBox.shrink()
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackLink(
                    label: 'Back to jobs',
                    onTap: () => context.go('/'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _Header(
                  job: job,
                  machine: machine,
                  mode: _mode,
                  onModeChanged: (m) => setState(() => _mode = m),
                ),
                if (job.description != null &&
                    job.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    job.description!,
                    style: context.text.smallMuted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _CommandStrip(job: job),
              ],
            ),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: fullscreen
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                  child: _mode == _DetailMode.terminal
                      ? JobTerminal(job: job, machine: machine)
                      : BenchmarkView(
                          jobId: job.id,
                          endpoint: endpoint,
                          host: host,
                          port: job.port,
                        ),
                ),
              ),
              if (!fullscreen)
                ActionsPanel(
                  job: job,
                  collapsed: _actionsCollapsed,
                  onToggle: () =>
                      setState(() => _actionsCollapsed = !_actionsCollapsed),
                  onKill: machine == null
                      ? null
                      : () => ref.read(jobExecutorProvider).kill(job, machine),
                  onRestart: machine == null
                      ? null
                      : () => ref.read(jobExecutorProvider).restart(job, machine),
                  onProfile: (machine == null || profiler.isBusy)
                      ? null
                      : () {
                          final notifier = ref.read(
                            profilerControllerProvider(job.id).notifier,
                          );
                          if (profiler.isReady) {
                            notifier.reopen();
                          } else {
                            notifier.run(
                              host: host,
                              port: job.port,
                              machine: machine,
                            );
                          }
                        },
                  onProfileStop: profiler.isReady
                      ? () => ref
                            .read(profilerControllerProvider(job.id).notifier)
                            .stop()
                      : null,
                  profilerTitle: profiler.isReady
                      ? 'Open profiler'
                      : 'Run profiler',
                  profilerSubtitle: switch (profiler.phase) {
                    ProfilerPhase.ready => 'xprof running',
                    ProfilerPhase.failed => profiler.message ?? 'failed',
                    _ => profiler.message ?? 'new tab',
                  },
                  onTest: () =>
                      showEndpointTest(context, host: host, port: job.port),
                  onDelete: () {
                    final id = job.id;
                    // Use the root container, not `ref`: this State unmounts on
                    // the navigation below, so its ref can't be used afterwards.
                    final container =
                        ProviderScope.containerOf(context, listen: false);
                    context.go('/');
                    // Tear the terminal down only AFTER the detail view has
                    // unmounted. Disposing the borrowed session (its flterm
                    // controller / native view) while the TerminalView is still
                    // on screen hard-crashes the app — so defer past this frame.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      container.invalidate(terminalMuxProvider(id));
                      container.read(jobExecutorProvider).remove(id);
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.job,
    required this.machine,
    required this.mode,
    required this.onModeChanged,
  });

  final Job job;
  final Machine? machine;
  final _DetailMode mode;
  final ValueChanged<_DetailMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left group takes all the free space (so the meta below sits flush
        // right); the name shrinks within it if the row gets tight.
        Expanded(
          child: Row(
            children: [
              StatusDot(job.status, size: 9),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  job.name,
                  style: context.text.title.copyWith(fontSize: 19),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              SegmentedControl<_DetailMode>(
                value: mode,
                onChanged: onModeChanged,
                options: const [
                  SegmentOption(
                    value: _DetailMode.terminal,
                    label: 'Terminal',
                    icon: AppIcons.terminal,
                  ),
                  SegmentOption(
                    value: _DetailMode.benchmark,
                    label: 'Benchmark',
                    icon: AppIcons.benchmark,
                  ),
                ],
              ),
            ],
          ),
        ),
        _Meta(label: 'host', value: machine?.name ?? job.machineId),
        _Meta(label: 'port', value: '${job.port}'),
      ],
    );
  }
}

/// The job's launch command as a one-line, horizontally scrollable strip.
/// Clicking it opens a popup where the full command wraps and can be copied.
class _CommandStrip extends StatelessWidget {
  const _CommandStrip({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: () => _showCommandPopup(context, job),
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: hovered ? c.surfaceHover : c.surfaceMuted,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: hovered ? c.borderStrong : c.borderMuted),
        ),
        child: Row(
          children: [
            Text(
              r'$',
              style: context.text.monoSmall.copyWith(color: c.textFaint),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  job.command,
                  style: context.text.monoSmall.copyWith(
                    color: c.textSecondary,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCommandPopup(BuildContext context, Job job) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      barrierLabel: 'Dismiss',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _CommandPopup(job: job),
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

class _CommandPopup extends StatelessWidget {
  const _CommandPopup({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
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
                    Icon(AppIcons.terminal, size: 15, color: c.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Launch command', style: context.text.bodyStrong),
                    const Spacer(),
                    CopyButton(text: job.command),
                    const SizedBox(width: AppSpacing.sm),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(color: c.borderMuted),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              job.command,
                              style: context.text.mono.copyWith(height: 1.6),
                            ),
                          ),
                        ),
                      ),
                      if (job.workingDir != null &&
                          job.workingDir!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Text('cd', style: context.text.monoSmall.copyWith(
                              color: c.textFaint,
                            )),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                job.workingDir!,
                                style: context.text.monoSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      child: Row(
        children: [
          Text(label, style: context.text.smallMuted),
          const SizedBox(width: 6),
          Text(value, style: context.text.monoSmall.copyWith(
            color: context.colors.textSecondary,
          )),
        ],
      ),
    );
  }
}
