import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/benchmark_controller.dart';

/// Opens a roomy popup for editing the benchmark prompt — handier than the
/// single-line field in the controls row for a long, multi-paragraph prompt.
/// Edits are written straight back to the run state, so the inline field and
/// the next request pick them up with nothing to save.
Future<void> showBenchmarkPromptEditor(BuildContext context, String jobId) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _PromptEditor(jobId: jobId),
      transitionsBuilder: (context, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

class _PromptEditor extends ConsumerStatefulWidget {
  const _PromptEditor({required this.jobId});

  final String jobId;

  @override
  ConsumerState<_PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends ConsumerState<_PromptEditor> {
  late final TextEditingController _prompt = TextEditingController(
    text: ref.read(benchmarkControllerProvider(widget.jobId)).prompt,
  );

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale with the window rather than sitting at a fixed size, so it grows
        // to give more room to write on a large display — but clamp both ways so
        // it never gets cramped on a small window or absurdly wide on a huge one.
        final width = (constraints.maxWidth * 0.62).clamp(480.0, 1100.0);
        final height = (constraints.maxHeight * 0.72).clamp(380.0, 900.0);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width, maxHeight: height),
              child: AppPanel(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const SectionLabel('Edit prompt'),
                        const Spacer(),
                        AppIconButton(
                          icon: AppIcons.close,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: AppTextField(
                        controller: _prompt,
                        mono: true,
                        expands: true,
                        autofocus: true,
                        onChanged: (v) => ref
                            .read(
                              benchmarkControllerProvider(widget.jobId).notifier,
                            )
                            .setPrompt(v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Spacer(),
                        AppButton(
                          label: 'Done',
                          variant: AppButtonVariant.primary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
