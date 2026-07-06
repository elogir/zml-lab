import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/search.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/machine.dart';
import '../../../repositories/machine_repository.dart';
import '../../jobs/application/jobs_providers.dart';
import '../application/machines_providers.dart';

class MachinesScreen extends ConsumerStatefulWidget {
  const MachinesScreen({super.key});

  @override
  ConsumerState<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends ConsumerState<MachinesScreen> {
  String _query = '';

  bool _matches(Machine m, String q) => matchesSearch(q, [
    m.name,
    m.address,
    m.vendor?.name,
    m.gpus,
    m.memory,
  ]);

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(machinesStreamProvider).value ?? const [];
    final q = _query.trim();
    final machines = q.isEmpty ? all : all.where((m) => _matches(m, q)).toList();

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Machines',
            subtitle:
                '${all.length} remote hosts available for inference jobs.',
            trailing: AppButton(
              label: 'Add machine',
              icon: AppIcons.add,
              variant: AppButtonVariant.primary,
              onPressed: () => context.go('/machines/new'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSearchField(
            hintText: 'Search machines',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: machines.isEmpty
                ? Center(
                    child: Text(
                      q.isEmpty ? 'No machines' : 'No matching machines',
                      style: context.text.smallMuted,
                    ),
                  )
                : SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = AppSpacing.lg;
                        final width = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final machine in machines)
                              SizedBox(
                                width: width,
                                child: _MachineCard(machine: machine),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MachineCard extends ConsumerWidget {
  const _MachineCard({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final jobs = ref.watch(jobsStreamProvider).value ?? const [];
    final running = jobs
        .where((j) => j.machineId == machine.id && j.status.isActive)
        .length;
    // Live probe: gray while the first check runs, then green/red.
    final up = ref.watch(machineReachableProvider(machine.id)).value;

    return AppCard(
      onTap: () => context.go('/machines/${machine.id}/edit'),
      onDelete: () =>
          ref.read(machineRepositoryProvider).deleteMachine(machine.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: up == null
                      ? c.textMuted
                      : up
                      ? c.statusRunning
                      : c.statusFailed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                machine.name,
                style: context.text.mono.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailRow(label: 'GPUs', value: machine.gpus ?? '—'),
          _DetailRow(label: 'Memory', value: machine.memory ?? '—'),
          _DetailRow(label: 'Running', value: '$running jobs'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: context.text.smallMuted),
          ),
          Expanded(child: Text(value, style: context.text.monoSmall)),
        ],
      ),
    );
  }
}
