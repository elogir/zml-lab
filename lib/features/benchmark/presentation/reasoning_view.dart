import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// The model's thinking output, shown above the answer for reasoning models —
/// dimmed and set off by a left rule so it reads as secondary to the reply.
///
/// [dense] is for the tight benchmark grid card: a smaller caption and no
/// vertical padding. [maxHeight] caps a long chain-of-thought (it crops; the
/// full text is in the expanded/focus views).
class ReasoningView extends StatelessWidget {
  const ReasoningView(
    this.reasoning, {
    super.key,
    this.dense = false,
    this.maxHeight,
  });

  final String reasoning;
  final bool dense;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget body = AppMarkdown(
      reasoning,
      style: context.text.smallMuted.copyWith(
        color: c.textFaint,
        height: 1.5,
      ),
    );
    if (maxHeight != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: ClipRect(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            reverse: true,
            child: body,
          ),
        ),
      );
    }
    return Container(
      margin: EdgeInsets.only(bottom: dense ? 6 : AppSpacing.sm),
      padding: EdgeInsets.only(
        left: dense ? 8 : AppSpacing.md,
        top: dense ? 0 : 2,
        bottom: dense ? 0 : 2,
      ),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.borderStrong, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'thinking',
            style: context.text.monoSmall.copyWith(
              color: c.textFaint,
              fontSize: dense ? 10 : 11,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          body,
        ],
      ),
    );
  }
}
