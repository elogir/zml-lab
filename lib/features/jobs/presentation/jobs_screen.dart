import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/job.dart';
import '../../new_job/presentation/new_job_modal.dart';
import '../application/jobs_providers.dart';

// Shared column geometry so header and rows line up exactly.
const double _machineW = 150;
const double _programW = 96;
const double _portW = 76;
const double _uptimeW = 92;

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(jobCountsProvider);
    final filter = ref.watch(jobFilterProvider);
    final entries = ref.watch(jobListProvider);

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
          PillTabs<JobFilterKind>(
            value: filter,
            onChanged: (k) => ref.read(jobFilterProvider.notifier).select(k),
            options: const [
              SegmentOption(value: JobFilterKind.all, label: 'All'),
              SegmentOption(value: JobFilterKind.running, label: 'Running'),
              SegmentOption(value: JobFilterKind.stopped, label: 'Stopped'),
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
          SizedBox(width: _programW, child: Text('PROGRAM', style: style)),
          SizedBox(width: _portW, child: Text('PORT', style: style)),
          SizedBox(width: _uptimeW, child: Text('UPTIME', style: style)),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.entry});

  final JobListEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final job = entry.job;
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
                  ),
                  const SizedBox(height: 2),
                  StatusLabel(job.status),
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
              width: _programW,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ProgramBadge(job.program),
              ),
            ),
            SizedBox(
              width: _portW,
              child: Text('${job.port}', style: context.text.monoSecondary),
            ),
            SizedBox(
              width: _uptimeW,
              child: _UptimeText(job: job),
            ),
            Icon(AppIcons.chevronRight, size: 16, color: c.textFaint),
          ],
        ),
      ),
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
