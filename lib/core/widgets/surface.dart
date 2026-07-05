import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_icon_button.dart';
import 'app_icons.dart';
import 'hover_region.dart';

/// A static bordered surface — the base container for panels and grouped
/// content.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.border,
    this.radius = AppRadius.lgAll,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Border? border;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: radius,
        border: border ?? Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

/// An interactive surface that lifts on hover and reacts to taps — used for
/// job rows, config cards, machine cards, list items.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onDuplicate,
    this.onDelete,
    this.topRight,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lgAll,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// If set, a duplicate button appears in the top-right corner on hover
  /// (left of the delete button).
  final VoidCallback? onDuplicate;

  /// If set, a delete button appears in the top-right corner on hover.
  final VoidCallback? onDelete;

  /// Metadata pinned to the top-right corner (e.g. a timestamp) while idle —
  /// the hover action buttons take over the same slot when hovered, so it
  /// reads as the timestamp being replaced by the trash icon.
  final Widget? topRight;

  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) {
        Widget content = Container(
          padding: padding,
          decoration: BoxDecoration(
            color: hovered ? c.surfaceHover : c.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? c.borderStrong
                  : (hovered ? c.borderStrong : c.border),
            ),
          ),
          child: child,
        );
        final showActions = (onDelete != null || onDuplicate != null) && hovered;
        final showTopRight = topRight != null && !showActions;
        if (showActions || showTopRight) {
          content = Stack(
            children: [
              content,
              Positioned(
                top: 6,
                right: 6,
                // A fixed-height box so the idle metadata and the hover
                // buttons share one vertical center and swap cleanly in place.
                child: SizedBox(
                  height: 27,
                  child: Center(
                    child: showActions
                        ? Row(
                            children: [
                              if (onDuplicate != null)
                                AppIconButton(
                                  icon: AppIcons.copy,
                                  size: 14,
                                  color: c.textMuted,
                                  onPressed: onDuplicate,
                                ),
                              if (onDelete != null)
                                AppIconButton(
                                  icon: AppIcons.delete,
                                  size: 15,
                                  color: c.textMuted,
                                  hoverColor: c.statusFailed,
                                  onPressed: onDelete,
                                ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: topRight,
                          ),
                  ),
                ),
              ),
            ],
          );
        }
        return content;
      },
    );
  }
}
