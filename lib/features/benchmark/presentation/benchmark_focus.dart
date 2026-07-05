import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark_chat.dart';
import '../application/benchmark_chat_controller.dart';

/// Opens the clicked benchmark request as a chat: its prompt and reply seed the
/// conversation, and the user can keep sending single requests and watch each
/// reply stream back.
Future<void> showBenchmarkFocus(
  BuildContext context,
  String jobId,
  int index,
  String host,
  int port,
) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) =>
          _ChatView(jobId: jobId, index: index, host: host, port: port),
      transitionsBuilder: (context, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView({
    required this.jobId,
    required this.index,
    required this.host,
    required this.port,
  });

  final String jobId;
  final int index;
  final String host;
  final int port;

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
    benchmarkChatControllerProvider(
      widget.jobId,
      widget.index,
      widget.host,
      widget.port,
    ).notifier,
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
      benchmarkChatControllerProvider(
      widget.jobId,
      widget.index,
      widget.host,
      widget.port,
    ),
    );
    // Follow the tail as tokens stream in.
    ref.listen(
      benchmarkChatControllerProvider(
      widget.jobId,
      widget.index,
      widget.host,
      widget.port,
    ),
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
                  child: ListView.separated(
                    controller: _scroll,
                    padding: EdgeInsets.zero,
                    itemCount: chat.turns.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, i) {
                      final turn = chat.turns[i];
                      // Selectable per turn (not across the whole list): one
                      // area spanning a lazy list whose items mount/unmount
                      // trips a selection-geometry race in the framework.
                      return AppSelectionArea(
                        child: _Turn(
                          turn: turn,
                          onReplay: turn.fromUser
                              ? () => _controller.replay(i)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                // Live stats of the in-flight reply, pinned so they stay put
                // while the transcript scrolls and the reply streams.
                if (chat.isStreaming) ...[
                  const SizedBox(height: AppSpacing.md),
                  _StreamingStats(turn: chat.turns.last),
                ],
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

/// One row in the transcript, Codex-style: the user's prompt on a full-width
/// tinted band (marked `›`, with a replay button on hover), or the model's
/// reply on the plain background (marked `•`) followed by its metrics.
class _Turn extends StatelessWidget {
  const _Turn({required this.turn, this.onReplay});

  final ChatTurn turn;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final marker = context.text.mono.copyWith(color: c.textFaint, height: 1.5);

    if (turn.fromUser) {
      return HoverRegion(
        cursor: SystemMouseCursors.basic,
        builder: (context, hovered) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: AppRadius.mdAll,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('›', style: marker),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  turn.text,
                  style: context.text.mono.copyWith(
                    color: c.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
              if (onReplay != null)
                // Reserve the slot always so revealing it doesn't reflow the
                // text; only interactive while hovered.
                IgnorePointer(
                  ignoring: !hovered,
                  child: Opacity(
                    opacity: hovered ? 1 : 0,
                    child: AppIconButton(
                      icon: AppIcons.restart,
                      size: 13,
                      padding: const EdgeInsets.all(6),
                      onPressed: onReplay,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: marker),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (turn.text.isEmpty)
                  Text(
                    '…',
                    style: context.text.mono.copyWith(
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                  )
                else
                  // The model's reply, rendered as markdown.
                  AppMarkdown(
                    turn.text,
                    style: context.text.bodySecondary.copyWith(height: 1.55),
                  ),
                // While streaming, the live stats are pinned above the composer
                // so they don't shift as the reply grows; the settled metrics
                // land here once it finishes.
                if (!turn.streaming) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _Metrics(turn: turn),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The in-flight reply's stats, pinned above the composer while it streams so
/// they don't move as the transcript grows.
class _StreamingStats extends StatelessWidget {
  const _StreamingStats({required this.turn});

  final ChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: AppRadius.mdAll,
      ),
      child: _Metrics(turn: turn),
    );
  }
}

/// The kept ttft / tokens / latency / throughput readout under a reply.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.turn});

  final ChatTurn turn;

  String _ms(int? v) => v == null ? '—' : '${v}ms';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tpsColor = turn.streaming ? c.statusStarting : c.textMuted;
    return Row(
      children: [
        _metric(context, 'ttft', _ms(turn.ttftMs)),
        const SizedBox(width: AppSpacing.lg),
        _metric(context, 'tok', '${turn.tokens}'),
        const SizedBox(width: AppSpacing.lg),
        _metric(context, 'lat', _ms(turn.latencyMs)),
        const SizedBox(width: AppSpacing.lg),
        if (turn.streaming) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: c.statusStarting,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          '${turn.tokensPerSecond.toStringAsFixed(1)} t/s',
          style: context.text.monoSmall.copyWith(color: tpsColor),
        ),
        if (!turn.streaming && turn.truncated) ...[
          const SizedBox(width: AppSpacing.lg),
          Text(
            'truncated',
            style: context.text.monoSmall.copyWith(color: c.statusStarting),
          ),
        ],
      ],
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final c = context.colors;
    return Row(
      children: [
        Text(label, style: context.text.monoSmall.copyWith(color: c.textFaint)),
        const SizedBox(width: 5),
        Text(value, style: context.text.monoSmall),
      ],
    );
  }
}
