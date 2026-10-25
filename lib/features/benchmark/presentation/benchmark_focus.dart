import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/execution/native_io.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/benchmark_chat.dart';
import '../application/benchmark_chat_controller.dart';
import 'reasoning_view.dart';

/// Opens the clicked benchmark request as a chat: its prompt and reply seed the
/// conversation, and the user can keep sending single requests and watch each
/// reply stream back.
Future<void> showBenchmarkFocus(
  BuildContext context,
  String jobId,
  int index,
  ChatEndpoint endpoint,
) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) =>
          _ChatView(jobId: jobId, index: index, endpoint: endpoint),
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
    required this.endpoint,
  });

  final String jobId;
  final int index;
  final ChatEndpoint endpoint;

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final TextEditingController _prompt = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// The transcript follows the newest text while this is on: off as soon as
  /// the user scrolls up, back on at the bottom (or with the button).
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    // Open on the end, streaming or finished: the newest reply is what the
    // card was clicked for. Again a frame later, as the lazy list sizes what
    // it builds on the way down.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _jumping = true;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      _jumping = false;
      _followToBottom();
    });
  }

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
      widget.endpoint,
    ).notifier,
  );

  void _send() {
    final text = _prompt.text;
    if (text.trim().isEmpty) return;
    _controller.send(text);
    _prompt.clear();
    _scrollToBottom();
  }

  /// To the bottom, and following from there (sending, or the button).
  void _scrollToBottom() {
    if (!_follow) setState(() => _follow = true);
    _followToBottom();
  }

  /// Once the new text is laid out: to the bottom, if following.
  void _followToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_follow && _scroll.hasClients) {
        _jumping = true;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
        _jumping = false;
      }
    });
  }

  /// Set while [_followToBottom] scrolls, so [_onScroll] only judges the
  /// user's scrolling.
  bool _jumping = false;

  /// The user's scrolling decides whether to follow. Taking hold of the list
  /// (a trackpad or touch drag starting) stops it at once: the jump after
  /// the next token would otherwise cancel the drag before it moved, so only
  /// a hard scroll got through. Any scroll up stops it too (a mouse wheel
  /// has no drag); scrolling back down to the bottom resumes it. Text
  /// arriving doesn't scroll, so it can't change it.
  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || _jumping) return false; // a code block's own scroll
    final m = n.metrics;
    switch (n) {
      case ScrollStartNotification(dragDetails: _?):
        if (_follow) setState(() => _follow = false);
      case ScrollUpdateNotification(:final scrollDelta?):
        // Up, and not the bounce back from overscrolling past the bottom.
        if (scrollDelta < 0 && m.pixels < m.maxScrollExtent) {
          if (_follow) setState(() => _follow = false);
        } else if (scrollDelta > 0 &&
            m.pixels >= m.maxScrollExtent - _bottomSlack) {
          if (!_follow) setState(() => _follow = true);
        }
      case ScrollEndNotification():
        // Let go without having moved off the bottom: keep following.
        if (!_follow && m.pixels >= m.maxScrollExtent - 1) {
          setState(() => _follow = true);
        }
      default:
    }
    return false;
  }

  /// How near the bottom counts as back at it.
  static const _bottomSlack = 24.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chat = ref.watch(
      benchmarkChatControllerProvider(
        widget.jobId,
        widget.index,
        widget.endpoint,
      ),
    );
    // Follow the tail as tokens stream in — unless the user scrolled away.
    ref.listen(
      benchmarkChatControllerProvider(
        widget.jobId,
        widget.index,
        widget.endpoint,
      ),
      (_, _) => _followToBottom(),
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
                      style: context.text.monoSmall.copyWith(
                        color: c.textFaint,
                      ),
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
                  child: Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: _onScroll,
                        child: ListView.separated(
                          controller: _scroll,
                          // A drag counts from where the fingers landed, so
                          // a light scroll moves by all of it.
                          dragStartBehavior: DragStartBehavior.down,
                          padding: EdgeInsets.zero,
                          itemCount: chat.turns.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, i) {
                            final turn = chat.turns[i];
                            // Selectable per turn (not across the whole
                            // list): one area spanning a lazy list whose
                            // items mount/unmount trips a selection-geometry
                            // race in the framework.
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
                      // Scrolled away from the end: back to it, and follow.
                      if (!_follow)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: AppSpacing.sm,
                          child: Center(
                            child: AppButton(
                              label: 'Scroll to bottom',
                              icon: AppIcons.toBottom,
                              dense: true,
                              onPressed: _scrollToBottom,
                            ),
                          ),
                        ),
                    ],
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
                if (turn.reasoning.isNotEmpty) ReasoningView(turn.reasoning),
                if (turn.error != null)
                  // The failure reason, in place of the (usually empty) reply.
                  Text(
                    turn.error!,
                    style: context.text.mono.copyWith(
                      color: c.statusFailed,
                      height: 1.5,
                    ),
                  )
                else if (turn.text.isEmpty)
                  // Placeholder only before anything (not while thinking) shows.
                  if (turn.reasoning.isEmpty)
                    Text(
                      '…',
                      style: context.text.mono.copyWith(
                        color: c.textSecondary,
                        height: 1.5,
                      ),
                    )
                  else
                    const SizedBox.shrink()
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
