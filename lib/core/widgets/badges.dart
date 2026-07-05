import 'package:flutter/widgets.dart';

import '../../models/enums.dart';
import '../theme/app_theme.dart';

/// The status color for a given [JobStatus], from the active palette.
Color statusColor(JobStatus status, AppColors c) => switch (status) {
  JobStatus.running => c.statusRunning,
  JobStatus.starting => c.statusStarting,
  JobStatus.failed => c.statusFailed,
  JobStatus.exited => c.statusExited,
};

/// A small filled dot signaling job status — the primary use of color.
class StatusDot extends StatelessWidget {
  const StatusDot(this.status, {super.key, this.size = 8, this.glow = true});

  final JobStatus status;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status, context.colors);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow && status.isActive
            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
            : null,
      ),
    );
  }
}

/// A status dot with its lowercase label beneath a title (dashboard rows).
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.status, {super.key});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status, context.colors);
    return Text(
      status.label,
      style: context.text.small.copyWith(color: color),
    );
  }
}

/// A tinted status pill (e.g. `running`) for the job detail header.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status, context.colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: context.text.small.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
