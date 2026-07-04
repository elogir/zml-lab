import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// A screen's title block: big title, optional subtitle, optional trailing
/// action (usually a primary button).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.title),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: context.text.subtitle),
              ],
            ],
          ),
        ),
        if (trailing != null) Padding(
          padding: const EdgeInsets.only(top: 2),
          child: trailing!,
        ),
      ],
    );
  }
}

/// A small, spaced, uppercase label for a group of controls or fields.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: context.text.sectionLabel);
}

/// A form field's label row, with an optional "optional/hint" suffix.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: context.text.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (hint != null) ...[
            const SizedBox(width: 6),
            Text('— $hint', style: context.text.smallMuted),
          ],
        ],
      ),
    );
  }
}
