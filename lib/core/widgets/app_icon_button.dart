import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'hover_region.dart';

/// A compact, borderless icon button that highlights on hover.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 16,
    this.color,
    this.hoverColor,
    this.padding = const EdgeInsets.all(6),
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  /// Icon color when hovered (e.g. red for a destructive action). The hover
  /// background is tinted to match.
  final Color? hoverColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onPressed,
      builder: (context, hovered) {
        final Color bg = hovered
            ? (hoverColor?.withValues(alpha: 0.14) ?? c.surfaceHover)
            : const Color(0x00000000);
        final Color fg = hovered
            ? (hoverColor ?? color ?? c.textPrimary)
            : (color ?? c.textMuted);
        return Container(
          padding: padding,
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
          child: Icon(icon, size: size, color: fg),
        );
      },
    );
  }
}

/// An icon-only on/off toggle, framed like a one-segment [SegmentedControl]:
/// the selected fill shows it's on, so the label doesn't have to flip between
/// "Show" and "Hide". Stretches to its parent's height when that is bounded,
/// so it lines up beside a segmented control in an [IntrinsicHeight] row.
class AppToggleIconButton extends StatelessWidget {
  const AppToggleIconButton({
    super.key,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      toggled: value,
      label: semanticLabel,
      child: HoverRegion(
        onTap: () => onChanged(!value),
        builder: (context, hovered) => Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: c.border),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: value
                  ? c.surfaceSelected
                  : (hovered ? c.surfaceHover : null),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              icon,
              size: 14,
              color: value || hovered ? c.textPrimary : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
