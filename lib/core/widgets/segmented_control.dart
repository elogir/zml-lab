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
    this.fill = false,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Fill the space given — equal-width segments, full height — instead of
  /// hugging the labels. Needs a bounded width (Expanded, IntrinsicWidth).
  final bool fill;

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
      child: _fit(
        Row(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: fill
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.center,
          children: [
            for (final option in options)
              _flexible(
                HoverRegion(
                  onTap: () => onChanged(option.value),
                  builder: (context, hovered) {
                    final selected = option.value == value;
                    return Container(
                      alignment: fill ? Alignment.center : null,
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _flexible(Widget segment) => fill ? Expanded(child: segment) : segment;

  /// Filling, the segments stretch to the height given — or, when none is,
  /// to their own (the sizing copy in FieldHeight gets an unbounded one).
  Widget _fit(Widget row) => fill ? IntrinsicHeight(child: row) : row;
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
