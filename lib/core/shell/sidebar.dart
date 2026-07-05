import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/configs/application/configs_providers.dart';
import '../../features/jobs/application/jobs_providers.dart';
import '../../features/machines/application/machines_providers.dart';
import '../../features/saved_benchmarks/application/saved_benchmarks_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

const double _expandedWidth = 232;
const double _collapsedWidth = 64;
const double _iconSize = 17;
const double _iconBox = 34; // collapsed highlight square
const double _itemHeight = 34;
const double _iconLeftPad = 12;
const double _labelGap = 12;

/// Inner width of an item when collapsed (rail width minus item padding). Used
/// as a *constant* anchor for the collapsed-centered positions so they don't
/// depend on the live (animating) item width — otherwise the icon position is
/// quadratic in `t` and visibly overshoots mid-animation.
const double _collapsedInner = _collapsedWidth - 2 * AppSpacing.sm;

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Left navigation rail. Every position is interpolated by the collapse value
/// [t] (1 = expanded, 0 = collapsed), so nothing re-wraps: icons slide from
/// centered to left, highlights shrink to an icon square, labels fade, and the
/// collapse toggle moves from the right to centered.
class Sidebar extends ConsumerWidget {
  const Sidebar({
    super.key,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final loc = GoRouterState.of(context).uri.path;

    final running = ref.watch(jobCountsProvider).running;
    final configCount =
        ref.watch(configsStreamProvider).value?.length ?? 0;
    final benchmarkCount =
        ref.watch(savedBenchmarksStreamProvider).value?.length ?? 0;
    final machineCount =
        ref.watch(machinesStreamProvider).value?.length ?? 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: collapsed ? 0.0 : 1.0),
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Container(
          width: _lerp(_collapsedWidth, _expandedWidth, t),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: c.window,
            border: Border(right: BorderSide(color: c.borderMuted)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ToggleBar(t: t, onToggle: onToggleCollapsed),
              _Logo(t: t),
              const SizedBox(height: AppSpacing.xs),
              _NavItem(
                t: t,
                icon: AppIcons.jobs,
                label: 'Jobs',
                badge: running,
                // The new-job form is contextual (pushed from any tab), so it
                // claims no tab; job detail still counts as Jobs.
                active: loc == '/' ||
                    (loc.startsWith('/jobs') && !loc.startsWith('/jobs/new')),
                onTap: () => context.go('/'),
              ),
              _NavItem(
                t: t,
                icon: AppIcons.configs,
                label: 'Saved configs',
                badge: configCount,
                active: loc.startsWith('/configs'),
                onTap: () => context.go('/configs'),
              ),
              _NavItem(
                t: t,
                icon: AppIcons.savedBenchmarks,
                label: 'Saved benchmarks',
                badge: benchmarkCount,
                active: loc.startsWith('/benchmarks'),
                onTap: () => context.go('/benchmarks'),
              ),
              _NavItem(
                t: t,
                icon: AppIcons.machines,
                label: 'Machines',
                badge: machineCount,
                active: loc.startsWith('/machines'),
                onTap: () => context.go('/machines'),
              ),
              const Spacer(),
              _NavItem(
                t: t,
                icon: AppIcons.settings,
                label: 'Settings',
                badge: 0,
                active: loc.startsWith('/settings'),
                onTap: () => context.go('/settings'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}

/// Brand mark shown under the collapse toggle, above the nav items. Only
/// visible when the sidebar is expanded — it fades and collapses its height to
/// zero (via [t]) so the rail leaves no gap when narrow.
class _Logo extends StatelessWidget {
  const _Logo({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.center,
        heightFactor: t,
        child: Opacity(
          opacity: t,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Center(
              child: Image.asset(
                'assets/images/zml_logo.png',
                width: 160,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleBar extends StatelessWidget {
  const _ToggleBar({required this.t, required this.onToggle});

  final double t;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: SizedBox(
        height: _itemHeight,
        // t: 0 → centered, 1 → right.
        child: Align(
          alignment: Alignment(t, 0),
          child: AppIconButton(
            icon: AppIcons.collapseSidebar,
            size: _iconSize,
            padding: const EdgeInsets.all(8),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.t,
    required this.icon,
    required this.label,
    required this.badge,
    required this.active,
    required this.onTap,
  });

  final double t;
  final IconData icon;
  final String label;
  final int badge;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = active ? c.textPrimary : c.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1.5,
      ),
      child: LayoutBuilder(
        builder: (context, cons) {
          final iw = cons.maxWidth;
          final highlightW = _lerp(_iconBox, iw, t);
          final highlightLeft = _lerp((_collapsedInner - _iconBox) / 2, 0, t);
          final iconLeft = _lerp((_collapsedInner - _iconSize) / 2, _iconLeftPad, t);
          const labelLeft = _iconLeftPad + _iconSize + _labelGap;
          final labelW = (iw - labelLeft - AppSpacing.md)
              .clamp(0.0, double.infinity);

          return HoverRegion(
            onTap: onTap,
            builder: (context, hovered) {
              final showBg = active || hovered;
              return SizedBox(
                height: _itemHeight,
                child: Stack(
                  children: [
                    if (showBg)
                      Positioned(
                        left: highlightLeft,
                        top: 0,
                        height: _itemHeight,
                        width: highlightW,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: active ? c.surfaceSelected : c.surfaceHover,
                            borderRadius: AppRadius.mdAll,
                          ),
                        ),
                      ),
                    Positioned(
                      left: iconLeft,
                      top: 0,
                      height: _itemHeight,
                      child: Center(
                        child: Icon(icon, size: _iconSize, color: fg),
                      ),
                    ),
                    Positioned(
                      left: labelLeft,
                      width: labelW,
                      top: 0,
                      height: _itemHeight,
                      child: Opacity(
                        opacity: t,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: context.text.body.copyWith(color: fg),
                                softWrap: false,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                            if (badge > 0)
                              Text('$badge', style: context.text.smallMuted),
                          ],
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
