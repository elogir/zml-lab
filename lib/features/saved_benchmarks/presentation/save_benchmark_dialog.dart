import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark.dart';
import '../../../models/saved_benchmark.dart';
import '../../../repositories/saved_benchmark_repository.dart';

/// Prompts for a name (pre-filled with [defaultName], the job's name) and
/// stores [run] (with its responses) as a [SavedBenchmark] against [endpoint].
Future<void> showSaveBenchmarkDialog(
  BuildContext context, {
  required BenchmarkRun run,
  required String endpoint,
  required String machineName,
  required String command,
  required String defaultName,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      barrierLabel: 'Dismiss',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _SaveDialog(
        run: run,
        endpoint: endpoint,
        machineName: machineName,
        command: command,
        defaultName: defaultName,
      ),
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

class _SaveDialog extends ConsumerStatefulWidget {
  const _SaveDialog({
    required this.run,
    required this.endpoint,
    required this.machineName,
    required this.command,
    required this.defaultName,
  });

  final BenchmarkRun run;
  final String endpoint;
  final String machineName;
  final String command;
  final String defaultName;

  @override
  ConsumerState<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends ConsumerState<_SaveDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.defaultName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final run = widget.run;
    ref
        .read(savedBenchmarkRepositoryProvider)
        .save(
          SavedBenchmark(
            id: 'b-${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            endpoint: widget.endpoint,
            machineName: widget.machineName,
            command: widget.command,
            prompt: run.prompt,
            batchSize: run.requests.length,
            aggregateTokensPerSecond: run.aggregateTokensPerSecond,
            completed: run.completed,
            medianTtftMs: run.medianTtftMs,
            elapsedMs: run.elapsed.inMilliseconds,
            createdAt: DateTime.now(),
            requests: run.requests,
            samples: run.samples,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                    Icon(AppIcons.save, size: 15, color: c.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Save benchmark', style: context.text.bodyStrong),
                    const Spacer(),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const FieldLabel('Name'),
                AppTextField(
                  controller: _name,
                  autofocus: true,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    const Spacer(),
                    AppButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: 'Save',
                      icon: AppIcons.save,
                      variant: AppButtonVariant.primary,
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
