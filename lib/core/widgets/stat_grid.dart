import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// Headline stats in equal-width columns: as many per row as fit at
/// [minCellWidth], and when they wrap the later rows reuse the same columns —
/// so a stat always sits under the one above it instead of drifting like
/// wrapped text.
class StatGrid extends StatelessWidget {
  const StatGrid({
    super.key,
    required this.children,
    this.minCellWidth = 112,
    this.rowSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double minCellWidth;
  final double rowSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = children.length;
        if (n == 0) return const SizedBox.shrink();
        final fit = (constraints.maxWidth / minCellWidth).floor().clamp(1, n);
        // Balance the rows (5 stats in 3 + 2, not 4 + 1).
        final rows = (n / fit).ceil();
        final perRow = (n / rows).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: rowSpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < perRow; col++)
                    Expanded(
                      child: r * perRow + col < n
                          ? Align(
                              alignment: Alignment.topLeft,
                              child: children[r * perRow + col],
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
