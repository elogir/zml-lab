import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'hover_region.dart';

enum AppButtonVariant { primary, secondary, ghost }

/// The app's one button, in three weights. Custom-drawn — no Material ink.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.secondary,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;

    return HoverRegion(
      onTap: onPressed,
      cursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      builder: (context, hovered) {
        final h = hovered && enabled;
        final (bg, fg, border) = switch (variant) {
          AppButtonVariant.primary => (
            h ? c.textPrimary : c.primaryButtonBg,
            c.primaryButtonFg,
            null,
          ),
          AppButtonVariant.secondary => (
            h ? c.surfaceHover : c.surfaceSelected,
            c.textPrimary,
            c.border,
          ),
          AppButtonVariant.ghost => (
            h ? c.surfaceHover : const Color(0x00000000),
            h ? c.textPrimary : c.textSecondary,
            null,
          ),
        };

        return Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 10 : 14,
              vertical: dense ? 6 : 9,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.mdAll,
              border: border == null ? null : Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: dense ? 14 : 15, color: fg),
                  const SizedBox(width: 7),
                ],
                Text(label, style: context.text.button.copyWith(color: fg)),
              ],
            ),
          ),
        );
      },
    );
  }
}
