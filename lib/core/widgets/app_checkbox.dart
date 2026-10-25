import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_icons.dart';

/// The bare check box: filled with the accent and ticked when [value]. Taps
/// are the parent's (a [HoverRegion] that passes [hovered] for the border).
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, this.hovered = false});

  final bool value;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: AppDurations.fast,
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: value ? c.accent : const Color(0x00000000),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: value ? c.accent : (hovered ? c.borderStrong : c.border),
        ),
      ),
      child: value
          ? const Icon(AppIcons.check, size: 11, color: Color(0xFFFFFFFF))
          : null,
    );
  }
}
