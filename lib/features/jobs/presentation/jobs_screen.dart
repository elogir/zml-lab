import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/execution/job_executor.dart';
import '../../../core/providers/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/util/search.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/job.dart';
import '../../job_detail/presentation/job_terminal.dart';
import '../../new_job/presentation/new_job_modal.dart';
import '../application/jobs_providers.dart';

// Shared column geometry so header and rows line up exactly.
const double _machineW = 150;
const double _portW = 76;
const double _uptimeW = 92;

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  String _query = '';

  bool _matches(JobListEntry e, String q) {
    final job = e.job;
    final machineName = e.machine?.name ?? job.machineId;
    return matchesSearch(q, [
      job.name,
      job.description,
      machineName,
      job.command,
      '${job.port}',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(jobCountsProvider);
    final filter = ref.watch(jobFilterProvider);
    final all = ref.watch(jobListProvider);
    final q = _query.trim();
    final entries = q.isEmpty ? all : all.where((e) => _matches(e, q)).toList();

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Jobs',
            subtitle: '${counts.running} running · ${counts.total} total',
            trailing: AppButton(
              label: 'New job',
              icon: AppIcons.add,
              variant: AppButtonVariant.primary,
              onPressed: () => showNewJobModal(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              PillTabs<JobFilterKind>(
                value: filter,
                onChanged: (k) =>
                    ref.read(jobFilterProvider.notifier).select(k),
                options: const [
                  SegmentOption(value: JobFilterKind.all, label: 'All'),
                  SegmentOption(value: JobFilterKind.running, label: 'Running'),
                  SegmentOption(value: JobFilterKind.stopped, label: 'Stopped'),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 280,
                child: AppSearchField(
                  hintText: 'Search jobs',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: _JobsTable(entries: entries),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobsTable extends StatelessWidget {
  const _JobsTable({required this.entries});

  final List<JobListEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (entries.isEmpty) {
      return AppPanel(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Text('No jobs to show.', style: context.text.smallMuted),
        ),
      );
    }
    return AppPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeaderRow(),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(color: c.borderMuted),
            _JobRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class Divider extends StatelessWidget {
  const Divider({super.key, required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(height: 1, color: color);
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = context.text.columnHeader;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(child: Text('JOB', style: style)),
          SizedBox(width: _machineW, child: Text('MACHINE', style: style)),
          SizedBox(width: _portW, child: Text('PORT', style: style)),
          SizedBox(width: _uptimeW, child: Text('UPTIME', style: style)),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _JobRow extends ConsumerWidget {
  const _JobRow({required this.entry});

  final JobListEntry entry;

  /// The job's description, trimmed, or null when there's nothing to show.
  static String? _description(Job job) {
    final d = job.description?.trim();
    return (d == null || d.isEmpty) ? null : d;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final job = entry.job;
    final machine = entry.machine;
    return HoverRegion(
      onTap: () => context.go('/jobs/${job.id}'),
      builder: (context, hovered) => Container(
        color: hovered ? c.surfaceHover : const Color(0x00000000),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md, top: 3),
              child: StatusDot(job.status),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.name,
                    style: context.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StatusLabel(job.status),
                      if (_description(job) != null) ...[
                        Text(
                          '  ·  ',
                          style: context.text.smallMuted.copyWith(
                            color: c.textFaint,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _description(job)!,
                            style: context.text.smallMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _machineW,
              child: Text(
                entry.machine?.name ?? job.machineId,
                style: context.text.monoSecondary,
              ),
            ),
            SizedBox(
              width: _portW,
              child: Text('${job.port}', style: context.text.monoSecondary),
            ),
            // Fixed-width trailing so swapping uptime↔actions on hover doesn't
            // shift the row. On hover, quick actions replace the uptime/chevron.
            SizedBox(
              width: _uptimeW + 20,
              child: (hovered && machine != null)
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: _QuickActions(
                        job: job,
                        onKill: () =>
                            ref.read(jobExecutorProvider).kill(job, machine),
                        onRestart: () => ref
                            .read(jobExecutorProvider)
                            .restart(job, machine),
                        onDelete: () {
                          ref.invalidate(terminalMuxProvider(job.id));
                          ref.read(jobExecutorProvider).remove(job.id);
                        },
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(child: _UptimeText(job: job)),
                        Icon(
                          AppIcons.chevronRight,
                          size: 16,
                          color: c.textFaint,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-job hover actions in the list: stop/relaunch a running job, or
/// relaunch/delete a stopped one — the common lifecycle without opening detail.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.job,
    required this.onKill,
    required this.onRestart,
    required this.onDelete,
  });

  final Job job;
  final VoidCallback onKill;
  final VoidCallback onRestart;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final danger = context.colors.statusFailed;
    // Restart always on the left, the destructive action (delete/kill) on the
    // right — so a button doesn't jump sides between running and stopped.
    final children = job.isStopped
        ? [
            _button(AppIcons.restart, onRestart),
            _button(AppIcons.delete, onDelete, hoverColor: danger),
          ]
        : [
            _button(AppIcons.restart, onRestart),
            _button(AppIcons.kill, onKill, hoverColor: danger),
          ];
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _button(IconData icon, VoidCallback onTap, {Color? hoverColor}) {
    return AppIconButton(
      icon: icon,
      size: 15,
      onPressed: onTap,
      hoverColor: hoverColor,
    );
  }
}

/// Ticking uptime — watches the clock so only this cell rebuilds each second.
class _UptimeText extends ConsumerWidget {
  const _UptimeText({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final uptime = job.uptimeAt(now);
    return Text(
      uptime == null ? '—' : formatUptime(uptime),
      style: context.text.monoSmall,
    );
  }
}
