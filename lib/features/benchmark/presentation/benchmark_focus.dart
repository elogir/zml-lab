import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark.dart';
import '../application/benchmark_controller.dart';
import 'benchmark_request_card.dart';

/// Expands a single benchmark request to fullscreen, where its response can be
/// watched large and a request sent manually.
Future<void> showBenchmarkFocus(BuildContext context, String jobId, int index) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _FocusView(jobId: jobId, index: index),
      transitionsBuilder: (context, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

class _FocusView extends ConsumerStatefulWidget {
  const _FocusView({required this.jobId, required this.index});

  final String jobId;
  final int index;

  @override
  ConsumerState<_FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends ConsumerState<_FocusView> {
  late final TextEditingController _prompt = TextEditingController(
    text: defaultBenchmarkPrompt,
  );

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final run = ref.watch(benchmarkControllerProvider(widget.jobId));
    final request = run.requests.firstWhere(
      (r) => r.index == widget.index,
      orElse: () => BenchmarkRequest(index: widget.index),
    );
    final dot = benchmarkStatusColor(request.status, c);

    // Scale with the window (clamped both ways) so it grows on a large display,
    // matching the prompt editor popup. The route fills the window, so the
    // media size is the space available to the dialog.
    final size = MediaQuery.sizeOf(context);
    final width = (size.width * 0.62).clamp(480.0, 1100.0);
    final height = (size.height * 0.72).clamp(380.0, 900.0);

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
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Request ${request.index.toString().padLeft(2, '0')}',
                      style: context.text.bodyStrong,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(request.status.label,
                        style: context.text.small.copyWith(color: dot)),
                    const Spacer(),
                    Text(
                      request.tokensPerSecond > 0
                          ? '${request.tokensPerSecond.toStringAsFixed(1)} t/s'
                          : '—',
                      style: context.text.mono.copyWith(
                        color: c.statusRunning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: AppPanel(
                    color: c.surfaceMuted,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SingleChildScrollView(
                      child: Text(
                        request.text.isEmpty
                            ? 'Waiting for tokens…'
                            : request.text,
                        style: context.text.mono.copyWith(
                          color: c.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _prompt,
                        prefix: '>',
                        mono: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      label: 'Send request',
                      icon: AppIcons.send,
                      variant: AppButtonVariant.primary,
                      onPressed: () => ref
                          .read(
                            benchmarkControllerProvider(widget.jobId).notifier,
                          )
                          .start(),
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
