import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark_chat.dart';
import '../application/benchmark_chat_controller.dart';

/// Opens the clicked benchmark request as a chat: its prompt and reply seed the
/// conversation, and the user can keep sending single requests and watch each
/// reply stream back.
Future<void> showBenchmarkFocus(BuildContext context, String jobId, int index) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _ChatView(jobId: jobId, index: index),
      transitionsBuilder: (context, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView({required this.jobId, required this.index});

  final String jobId;
  final int index;

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final TextEditingController _prompt = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _prompt.dispose();
    _scroll.dispose();
    super.dispose();
  }

  BenchmarkChatController get _controller => ref.read(
    benchmarkChatControllerProvider(widget.jobId, widget.index).notifier,
  );

  void _send() {
    final text = _prompt.text;
    if (text.trim().isEmpty) return;
    _controller.send(text);
    _prompt.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chat = ref.watch(
      benchmarkChatControllerProvider(widget.jobId, widget.index),
    );
    // Follow the tail as tokens stream in.
    ref.listen(
      benchmarkChatControllerProvider(widget.jobId, widget.index),
      (_, _) => _scrollToBottom(),
    );

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
                    Icon(AppIcons.benchmark, size: 15, color: c.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Chat', style: context.text.bodyStrong),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'request ${widget.index.toString().padLeft(2, '0')}',
                      style: context.text.monoSmall.copyWith(color: c.textFaint),
                    ),
                    const Spacer(),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxBubble = constraints.maxWidth * 0.82;
                      return ListView.separated(
                        controller: _scroll,
                        padding: EdgeInsets.zero,
                        itemCount: chat.turns.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) =>
                            _Bubble(turn: chat.turns[i], maxWidth: maxBubble),
                      );
                    },
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
                        autofocus: true,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      label: 'Send',
                      icon: AppIcons.send,
                      variant: AppButtonVariant.primary,
                      onPressed: chat.isStreaming ? null : _send,
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

/// A single chat message — the user's prompt (right, filled) or the model's
/// reply (left, bordered) with a live tokens/sec readout while it streams.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn, required this.maxWidth});

  final ChatTurn turn;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (turn.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: c.border),
            ),
            child: Text(
              turn.text,
              style: context.text.mono.copyWith(color: c.textPrimary),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: c.borderMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                turn.text.isEmpty ? '…' : turn.text,
                style: context.text.mono.copyWith(
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              if (turn.streaming) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.statusStarting,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${turn.tokensPerSecond.toStringAsFixed(0)} t/s',
                      style: context.text.monoSmall.copyWith(
                        color: c.statusStarting,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
