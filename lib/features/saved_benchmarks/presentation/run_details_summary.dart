import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/run_meta.dart';

/// Under a saved run's title: the details typed for it (hardware, server
/// version and commit, tags), then its notes. Nothing when there are none.
class RunDetailsSummary extends StatelessWidget {
  const RunDetailsSummary({super.key, required this.details});

  final RunDetails details;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = details;
    final server = [
      if (d.serverVersion.isNotEmpty) d.serverVersion,
      if (d.serverCommit.isNotEmpty) '@ ${d.serverCommit}',
    ].join(' ');
    final line = [
      if (d.hardware.isNotEmpty) d.hardware,
      if (server.isNotEmpty) server,
      if (d.tags.isNotEmpty) d.tags.map((t) => '#$t').join(' '),
    ].join('  ·  ');
    if (line.isEmpty && d.notes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (line.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            line,
            style: context.text.monoSmall.copyWith(color: c.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (d.notes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            d.notes,
            style: context.text.small.copyWith(color: c.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
