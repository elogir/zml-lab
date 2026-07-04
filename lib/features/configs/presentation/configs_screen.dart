import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/launch_config.dart';
import '../../../repositories/config_repository.dart';
import '../../machines/application/machines_providers.dart';
import '../../new_job/presentation/new_job_modal.dart';
import '../application/configs_providers.dart';

class ConfigsScreen extends ConsumerWidget {
  const ConfigsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(configsStreamProvider).value ?? const [];

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
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: SingleChildScrollView(
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
