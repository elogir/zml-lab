import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/execution/job_executor.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/search.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../models/launch_config.dart';
import '../../configs/application/configs_providers.dart';
import '../../machines/application/machines_providers.dart';

/// Opens the custom job form, optionally pre-filled from a saved config.
/// Pushed (not `go`) so the form's Back returns to the screen it was opened
/// from — the configs tab stays the configs tab. Uses the typed route so the
/// query key always matches the generated one.
void openConfigInForm(BuildContext context, String configId) =>
    NewCustomJobRoute(configId: configId).push<void>(context);

/// Presents the "New job" chooser as a centered modal over the current
/// screen: pick a saved config to launch it right away, or build a custom job.
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
          'Pick a config to launch it right away, or build a custom job. '
          'To tweak one first, edit it under Saved configs.',
          style: context.text.subtitle,
        ),
      ],
    );
  }
}

class _ModalBody extends ConsumerStatefulWidget {
  const _ModalBody();

  @override
  ConsumerState<_ModalBody> createState() => _ModalBodyState();
}

class _ModalBodyState extends ConsumerState<_ModalBody> {
  String _query = '';

  /// Tallest the config list gets before it scrolls (~5 rows).
  static const double _listMaxHeight = 300;

  void _openCustom(BuildContext context) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    // Push so the form's Back returns to the screen the modal was opened on.
    router.push<void>(const NewCustomJobRoute().location);
  }

  /// Launches [config] as-is: builds a job from it and starts it immediately,
  /// landing on the job's detail view.
  Future<void> _launchConfig(LaunchConfig config) async {
    final machine = ref.read(machineMapProvider)[config.machineId];
    if (machine == null) return;
    // Grab everything up front: popping the modal unmounts this widget, so
    // neither `context` nor `ref` can be touched after the await.
    final router = GoRouter.of(context);
    final executor = ref.read(jobExecutorProvider);
    Navigator.of(context).pop();

    final job = Job(
      id: 'job-${DateTime.now().microsecondsSinceEpoch}',
      name: config.name,
      description: config.description,
      machineId: config.machineId,
      command: config.command,
      workingDir: config.workingDir,
      port: config.port,
      status: JobStatus.starting,
      env: config.env,
    );
    await executor.launch(job, machine);
    router.go('/jobs/${job.id}');
  }

  bool _matches(LaunchConfig c, String q, String machineName) =>
      matchesSearch(q, [
        c.name,
        c.description,
        c.command,
        machineName,
        '${c.port}',
      ]);

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(configsStreamProvider).value ?? const [];
    final machines = ref.watch(machineMapProvider);
    final q = _query.trim();
    final configs = q.isEmpty
        ? all
        : [
            for (final c in all)
              if (_matches(c, q, machines[c.machineId]?.name ?? c.machineId)) c,
          ];

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
          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('No saved configs yet', style: context.text.smallMuted),
            )
          else ...[
            AppSearchField(
              hintText: 'Search configs',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Capped and scrollable so a long config library doesn't grow the
            // modal off screen.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _listMaxHeight),
              child: configs.isEmpty
                  ? Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        'No matching configs',
                        style: context.text.smallMuted,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: configs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final config = configs[i];
                        final machine = machines[config.machineId];
                        return _ConfigRow(
                          config: config,
                          machineName: machine?.name ?? config.machineId,
                          onLaunch: machine == null
                              ? null
                              : () => _launchConfig(config),
                        );
                      },
                    ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
    required this.onLaunch,
  });

  final LaunchConfig config;
  final String machineName;

  /// Starts the config immediately. Null when its machine no longer exists.
  final VoidCallback? onLaunch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final description = config.description;
    return AppCard(
      onTap: onLaunch,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: context.text.smallMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$machineName · :${config.port}',
            style: context.text.monoSmall,
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(
            AppIcons.play,
            size: 14,
            color: onLaunch == null ? c.textFaint : c.textSecondary,
          ),
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
                  'Configure machine, command, port and env from scratch',
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
