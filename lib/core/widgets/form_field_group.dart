import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'app_text_field.dart';
import 'hover_region.dart';
import 'section_header.dart';

/// A labeled text input — the standard building block for the app's forms.
class LabeledInput extends StatelessWidget {
  const LabeledInput({
    super.key,
    required this.label,
    this.hint,
    this.placeholder,
    this.prefix,
    this.controller,
    this.mono = false,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final String? placeholder;
  final String? prefix;
  final TextEditingController? controller;
  final bool mono;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, hint: hint),
        AppTextField(
          controller: controller,
          placeholder: placeholder,
          prefix: prefix,
          mono: mono,
          minLines: minLines,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

/// A `‹ Back to …` link that sits above a form/detail title.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.chevronLeft,
            size: 15,
            color: hovered ? c.textPrimary : c.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.text.small.copyWith(
              color: hovered ? c.textPrimary : c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
