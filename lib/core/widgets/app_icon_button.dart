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
