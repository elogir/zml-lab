import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/job.dart';

const double _expandedWidth = 240;
const double _collapsedWidth = 60;
const double _iconSize = 15;
const double _iconBox = 38; // collapsed highlight square (kept ~square)
const double _tileHeight = 54;
const double _iconLeftPad = 12;
const double _labelGap = 12;

/// Inner width of a tile when collapsed — a constant anchor for the
/// collapsed-centered positions (see the sidebar for why this must not depend
/// on the live animating width).
const double _collapsedInner = _collapsedWidth - 2 * AppSpacing.sm;

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// The collapsible list of per-job actions on the right of the detail view.
/// Uses the same `t`-driven interpolation as the sidebar so it animates
/// smoothly: icons slide centered↔left, highlights grow from an icon square to
/// a full row, labels fade, and the toggle moves centered↔right.
class ActionsPanel extends StatelessWidget {
  const ActionsPanel({
    super.key,
    required this.job,
    required this.collapsed,
    required this.onToggle,
    this.onKill,
    this.onRestart,
    this.onProfile,
    this.onProfileStop,
    this.profilerTitle = 'Run profiler',
    this.profilerSubtitle = 'new tab',
    this.onTest,
    this.onDelete,
  });

  final Job job;
  final bool collapsed;
  final VoidCallback onToggle;

  /// Stops the running process. Null when there's nothing to kill.
  final VoidCallback? onKill;

  /// Stops (if needed) and relaunches the job's process.
  final VoidCallback? onRestart;

  /// Captures a profile trace and opens it in xprof, or (once ready) re-opens
  /// its tab. Null while a capture is in flight.
  final VoidCallback? onProfile;

  /// Stops the running xprof server. Non-null only once a profiler is ready.
  final VoidCallback? onProfileStop;

  /// Title of the profiler tile ('Run profiler' or 'Open profiler').
  final String profilerTitle;

  /// Live status line for the profiler tile ('new tab', 'capturing trace…', …).
  final String profilerSubtitle;

  /// Probes the job's endpoint (opens a result popup).
  final VoidCallback? onTest;

  /// Deletes the job (stops it if needed and removes the row).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: collapsed ? 0.0 : 1.0),
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Container(
          width: _lerp(_collapsedWidth, _expandedWidth, t),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.borderMuted)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(t: t, collapsed: collapsed, onToggle: onToggle),
              const SizedBox(height: AppSpacing.xs),
              if (!job.isStopped)
                _ActionTile(
                  t: t,
                  icon: AppIcons.kill,
                  title: 'Kill process',
                  subtitle: 'SIGINT ${job.pid ?? '—'}',
                  danger: true,
                  onTap: onKill,
                ),
              _ActionTile(
                t: t,
                icon: AppIcons.profiler,
                title: profilerTitle,
                subtitle: profilerSubtitle,
                onTap: onProfile,
                trailing: onProfileStop == null
                    ? null
                    : AppIconButton(
                        icon: AppIcons.kill,
                        size: 13,
                        color: c.statusFailed,
                        padding: const EdgeInsets.all(6),
                        onPressed: onProfileStop,
                      ),
              ),
              _ActionTile(
                t: t,
                icon: AppIcons.restart,
                title: 'Restart',
                subtitle: 'relaunch process',
                onTap: onRestart,
              ),
              _ActionTile(
                t: t,
                icon: AppIcons.testEndpoint,
                title: 'Test endpoint',
                subtitle: ':${job.port}/v1',
                onTap: onTest,
              ),
              if (job.isStopped)
                _ActionTile(
                  t: t,
                  icon: AppIcons.delete,
                  title: 'Delete job',
                  subtitle: 'remove from list',
                  danger: true,
                  onTap: onDelete,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.t,
    required this.collapsed,
    required this.onToggle,
  });

  final double t;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        0,
        AppSpacing.xs,
      ),
      child: SizedBox(
        height: 32,
        child: Stack(
          children: [
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(opacity: t, child: const SectionLabel('Actions')),
              ),
            ),
            // Anchored to the pinned right edge so its absolute position stays
            // monotonic: expanded → 8px from right, collapsed → centered in the
            // rail. (Aligning within the animating width would overshoot.)
            Positioned(
              right: _lerp((_collapsedWidth - 32) / 2, 8, t),
              top: 0,
              height: 32,
              child: AppIconButton(
                icon: collapsed ? AppIcons.chevronLeft : AppIcons.chevronRight,
                size: 16,
                padding: const EdgeInsets.all(8),
                onPressed: onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
    this.onTap,
    this.trailing,
  });

  final double t;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback? onTap;

  /// Optional control pinned to the tile's right edge (e.g. a stop button),
  /// shown only when expanded.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = danger ? c.statusFailed : c.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1.5,
      ),
      child: LayoutBuilder(
        builder: (context, cons) {
          final iw = cons.maxWidth;
          // The whole tile shrinks to the icon-box square when collapsed (like
          // the nav rail) so collapsed icons pack at the same tight gap as the
          // sidebar — otherwise a fixed 54px tile leaves big dead bands and the
          // icons drift far apart. Expanded it grows to fit title + subtitle.
          final tileHeight = _lerp(_iconBox, _tileHeight, t);
          final highlightW = _lerp(_iconBox, iw, t);
          final highlightLeft = _lerp((_collapsedInner - _iconBox) / 2, 0, t);
          final iconLeft = _lerp((_collapsedInner - _iconSize) / 2, _iconLeftPad, t);
          const labelLeft = _iconLeftPad + _iconSize + _labelGap;
          final trailingW = trailing == null ? 0.0 : 34.0;
          final labelW = (iw - labelLeft - AppSpacing.md - trailingW)
              .clamp(0.0, double.infinity);

          return HoverRegion(
            onTap: onTap ?? () {},
            builder: (context, hovered) {
              final showBg = danger || hovered;
              final bg = danger
                  ? c.statusFailed.withValues(alpha: hovered ? 0.16 : 0.10)
                  : c.surfaceHover;
              return SizedBox(
                height: tileHeight,
                child: Stack(
                  children: [
                    if (showBg)
                      Positioned(
                        left: highlightLeft,
                        top: 0,
                        height: tileHeight,
                        width: highlightW,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: AppRadius.mdAll,
                            border: danger
                                ? Border.all(
                                    color: c.statusFailed.withValues(alpha: 0.35),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    Positioned(
                      left: iconLeft,
                      top: 0,
                      height: tileHeight,
                      child: Center(
                        child: Icon(icon, size: _iconSize, color: tint),
                      ),
                    ),
                    Positioned(
                      left: labelLeft,
                      width: labelW,
                      top: 0,
                      height: tileHeight,
                      child: Opacity(
                        opacity: t,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: context.text.button.copyWith(color: tint),
                              softWrap: false,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: context.text.smallMuted,
                              softWrap: false,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Positioned(
                        right: AppSpacing.sm,
                        top: 0,
                        height: tileHeight,
                        child: Center(
                          child: IgnorePointer(
                            ignoring: t < 0.9,
                            child: Opacity(opacity: t, child: trailing),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
