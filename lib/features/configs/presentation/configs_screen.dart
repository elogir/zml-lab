import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/launch_config.dart';
import '../../../repositories/config_repository.dart';
import '../../machines/application/machines_providers.dart';
import '../../new_job/presentation/new_job_modal.dart';
import '../application/configs_providers.dart';

class ConfigsScreen extends ConsumerStatefulWidget {
  const ConfigsScreen({super.key});

  @override
  ConsumerState<ConfigsScreen> createState() => _ConfigsScreenState();
}

class _ConfigsScreenState extends ConsumerState<ConfigsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(configsStreamProvider).value ?? const [];
    final machines = ref.watch(machineMapProvider);
    final q = _query.trim().toLowerCase();

    bool matches(LaunchConfig c) {
      final machineName = machines[c.machineId]?.name ?? c.machineId;
      return c.name.toLowerCase().contains(q) ||
          (c.description?.toLowerCase().contains(q) ?? false) ||
          c.program.toLowerCase().contains(q) ||
          c.command.toLowerCase().contains(q) ||
          machineName.toLowerCase().contains(q) ||
          '${c.port}'.contains(q);
    }

    final configs = q.isEmpty ? all : all.where(matches).toList();

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Saved configs',
            subtitle: 'Reusable launch presets. Pick one to pre-fill the job form.',
            trailing: AppButton(
              label: 'New job',
              icon: AppIcons.add,
              variant: AppButtonVariant.primary,
              onPressed: () => showNewJobModal(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSearchField(
            hintText: 'Search configs',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: configs.isEmpty
                ? Center(
                    child: Text(
                      q.isEmpty ? 'No saved configs' : 'No matching configs',
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
                            for (final config in configs)
                              SizedBox(
                                width: width,
                                child: _ConfigCard(config: config),
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

class _ConfigCard extends ConsumerWidget {
  const _ConfigCard({required this.config});

  final LaunchConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machine = ref.watch(machineMapProvider)[config.machineId];
    final machineName = machine?.name ?? config.machineId;

    return AppCard(
      onTap: () => openConfigInForm(context, config.id),
      onDelete: () =>
          ref.read(configRepositoryProvider).deleteConfig(config.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.name,
            style: context.text.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (config.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(config.description!, style: context.text.smallMuted),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(machineName, style: context.text.monoSmall),
              const SizedBox(width: AppSpacing.md),
              Text(':${config.port}', style: context.text.monoSmall),
            ],
          ),
        ],
      ),
    );
  }
}
