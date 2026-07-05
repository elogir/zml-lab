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

  /// Saves a copy of this config under the first free "<name> copy [n]" name.
  Future<void> _duplicate(WidgetRef ref) {
    final all = ref.read(configsStreamProvider).value ?? const [];
    final names = {for (final c in all) c.name};
    var name = '${config.name} copy';
    for (var n = 2; names.contains(name); n++) {
      name = '${config.name} copy $n';
    }
    return ref.read(configRepositoryProvider).upsertConfig(
      config.copyWith(
        id: 'cfg-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machine = ref.watch(machineMapProvider)[config.machineId];
    final machineName = machine?.name ?? config.machineId;
    final description = config.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return AppCard(
      onTap: () => openConfigInForm(context, config.id),
      onDuplicate: () => _duplicate(ref),
      onDelete: () =>
          ref.read(configRepositoryProvider).deleteConfig(config.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.name,
            style: context.text.body.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Always exactly one middle line so every card is the same height —
          // without a description, the command is a more useful filler than a
          // blank gap.
          Text(
            hasDescription ? description : config.command,
            style: hasDescription
                ? context.text.smallMuted
                : context.text.monoSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
