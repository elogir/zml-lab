import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'hover_region.dart';

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// A grouped segmented toggle (e.g. Terminal | Benchmark).
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            HoverRegion(
              onTap: () => onChanged(option.value),
              builder: (context, hovered) {
                final selected = option.value == value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? c.surfaceSelected : null,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (option.icon != null) ...[
                        Icon(
                          option.icon,
                          size: 14,
                          color: selected ? c.textPrimary : c.textMuted,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        option.label,
                        style: context.text.button.copyWith(
                          color: selected ? c.textPrimary : c.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Standalone pill tabs (e.g. All / Running / Stopped filters).
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options) ...[
          HoverRegion(
            onTap: () => onChanged(option.value),
            builder: (context, hovered) {
              final selected = option.value == value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? c.surfaceSelected
                      : (hovered ? c.surfaceHover : null),
                  borderRadius: AppRadius.pillAll,
                  border: Border.all(
                    color: selected ? c.border : const Color(0x00000000),
                  ),
                ),
                child: Text(
                  option.label,
                  style: context.text.button.copyWith(
                    color: selected ? c.textPrimary : c.textMuted,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}
