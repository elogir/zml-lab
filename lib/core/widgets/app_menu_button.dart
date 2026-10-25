import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'hover_region.dart';
import 'surface.dart';

/// One choice in an [AppMenuButton]'s list.
class AppMenuItem<T> {
  const AppMenuItem({required this.value, required this.label, this.detail});

  final T value;
  final String label;

  /// Faint text at the row's right (a count, a direction).
  final String? detail;
}

/// A compact button that drops down a list to pick one value from — the
/// Saved benchmarks filters and sort. It says [label]; the list marks the
/// item whose value is [value]. [active] tints it, for a filter that's set.
class AppMenuButton<T> extends StatefulWidget {
  const AppMenuButton({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onSelected,
    this.icon,
    this.active = false,
    this.menuWidth = 240,
  });

  final String label;
  final List<AppMenuItem<T>> items;
  final T value;
  final ValueChanged<T> onSelected;
  final IconData? icon;
  final bool active;
  final double menuWidth;

  @override
  State<AppMenuButton<T>> createState() => _AppMenuButtonState<T>();
}

class _AppMenuButtonState<T> extends State<AppMenuButton<T>> {
  final _link = LayerLink();
  final _menu = OverlayPortalController();

  void _pick(T value) {
    _menu.hide();
    widget.onSelected(value);
  }

  /// The room between the button and the window's bottom edge, so the list
  /// scrolls only when the window is too short to show it all.
  double _maxHeight(BuildContext overlay) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 320;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final room = MediaQuery.sizeOf(overlay).height - bottom;
    return math.max(120, room - 4 - AppSpacing.md);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = HoverRegion(
      onTap: () => _menu.isShowing ? _menu.hide() : _menu.show(),
      builder: (context, hovered) {
        final fg = widget.active
            ? c.accent
            : (hovered ? c.textPrimary : c.textSecondary);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? c.accent.withValues(alpha: hovered ? 0.16 : 0.1)
                : (hovered ? c.surfaceHover : c.surface),
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: widget.active
                  ? c.accent.withValues(alpha: 0.35)
                  : c.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 13, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    widget.label,
                    style: context.text.button.copyWith(color: fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(AppIcons.chevronDown, size: 13, color: fg),
            ],
          ),
        );
      },
    );

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _menu,
        overlayChildBuilder: (overlay) => Stack(
          children: [
            // Tap outside to dismiss.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _menu.hide,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.menuWidth,
                    minWidth: math.min(160, widget.menuWidth),
                    maxHeight: _maxHeight(overlay),
                  ),
                  child: IntrinsicWidth(
                    child: AppPanel(
                      color: c.surface,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in widget.items)
                              _MenuRow(
                                item: item,
                                selected: item.value == widget.value,
                                onTap: () => _pick(item.value),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        child: button,
      ),
    );
  }
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppMenuItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: 0.12)
              : (hovered ? c.surfaceHover : null),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: selected
                  ? Icon(AppIcons.check, size: 12, color: c.accent)
                  : null,
            ),
            Flexible(
              fit: FlexFit.tight,
              child: Text(
                item.label,
                style: context.text.body.copyWith(
                  color: selected ? c.accent : c.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.detail != null) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                item.detail!,
                style: context.text.monoSmall.copyWith(color: c.textFaint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
