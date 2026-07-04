import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/launch_config.dart';
import '../../configs/application/configs_providers.dart';
import '../../machines/application/machines_providers.dart';

/// Opens the custom job form, optionally pre-filled from a saved config.
/// Uses the typed route so the query key always matches the generated one.
void openConfigInForm(BuildContext context, String configId) =>
    NewCustomJobRoute(configId: configId).go(context);

/// Presents the "New job" chooser as a centered modal over the current
/// screen: pick a saved config, or build a custom job.
Future<void> showNewJobModal(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      barrierLabel: 'Dismiss',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => const _NewJobModal(),
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

class _NewJobModal extends StatelessWidget {
  const _NewJobModal();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppPanel(
            color: c.surface,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: _ModalHeader(),
                ),
                _ModalBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New job',
          style: context.text.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          'Start from a saved config, or build a custom one from scratch.',
          style: context.text.subtitle,
        ),
      ],
    );
  }
}

class _ModalBody extends ConsumerWidget {
  const _ModalBody();

  void _openCustom(BuildContext context, {String? configId}) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(NewCustomJobRoute(configId: configId).location);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(configsStreamProvider).value ?? const [];
    final machines = ref.watch(machineMapProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionLabel('Saved configs'),
          const SizedBox(height: AppSpacing.sm),
          for (final config in configs) ...[
            _ConfigRow(
              config: config,
              machineName: machines[config.machineId]?.name ?? config.machineId,
              onTap: () => _openCustom(context, configId: config.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          _CustomRow(onTap: () => _openCustom(context)),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.config,
    required this.machineName,
    required this.onTap,
  });

  final LaunchConfig config;
  final String machineName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.name,
                  style: context.text.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$machineName · ${config.program} · :${config.port}',
                  style: context.text.monoSmall,
                ),
              ],
            ),
          ),
          ProgramBadge(config.program),
          const SizedBox(width: AppSpacing.md),
          Icon(AppIcons.chevronRight, size: 16, color: c.textFaint),
        ],
      ),
    );
  }
}

class _CustomRow extends StatelessWidget {
  const _CustomRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceSelected,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: c.border),
            ),
            child: Icon(AppIcons.add, size: 16, color: c.textPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build a custom job',
                  style: context.text.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Configure machine, program, args and env from scratch',
                  style: context.text.smallMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
