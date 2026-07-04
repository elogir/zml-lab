import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/job.dart';
import '../../../models/machine.dart';
import '../../benchmark/presentation/benchmark_view.dart';
import '../../machines/application/machines_providers.dart';
import '../application/job_detail_providers.dart';
import '../application/terminal_fullscreen.dart';
import 'actions_panel.dart';
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackLink(label: 'Back to jobs', onTap: () => context.go('/')),
                const SizedBox(height: AppSpacing.md),
                _Header(
                  job: job,
                  machine: machine,
                  mode: _mode,
                  onModeChanged: (m) => setState(() => _mode = m),
                ),
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
                      : BenchmarkView(jobId: job.id, endpoint: endpoint),
                ),
              ),
              if (!fullscreen)
                ActionsPanel(
                  job: job,
                  collapsed: _actionsCollapsed,
                  onToggle: () =>
                      setState(() => _actionsCollapsed = !_actionsCollapsed),
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
        const Spacer(),
        _Meta(label: 'host', value: machine?.name ?? job.machineId),
        _Meta(label: 'port', value: '${job.port}'),
      ],
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
