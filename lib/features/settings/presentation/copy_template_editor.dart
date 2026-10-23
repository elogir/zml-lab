import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../benchmark/domain/result_template.dart';

/// Edits the "Copy results" template: presets to start from, the template
/// itself, clickable placeholders, and a live preview on an example run.
class CopyTemplateEditor extends StatefulWidget {
  const CopyTemplateEditor({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  /// Owned by the settings screen, so Reset to defaults can rewrite it.
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<CopyTemplateEditor> createState() => _CopyTemplateEditorState();
}

class _CopyTemplateEditorState extends State<CopyTemplateEditor> {
  static final _example = resultValues(BenchmarkResult.example());

  void _set(String template) {
    widget.controller.value = TextEditingValue(
      text: template,
      selection: TextSelection.collapsed(offset: template.length),
    );
    widget.onChanged(template);
    setState(() {});
  }

  /// Puts `{name}` at the cursor (replacing a selection), or at the end when
  /// the field was never focused.
  void _insert(String name) {
    final value = widget.controller.value;
    final token = '{$name}';
    final sel = value.selection;
    final start = sel.isValid ? sel.start : value.text.length;
    final end = sel.isValid ? sel.end : value.text.length;
    final text = value.text.replaceRange(start, end, token);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
    widget.onChanged(text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Text('Start from', style: context.text.smallMuted),
            ),
            for (final (name, template) in resultTemplatePresets)
              AppButton(
                label: name,
                variant: AppButtonVariant.ghost,
                dense: true,
                onPressed: () => _set(template),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: widget.controller,
          mono: true,
          minLines: 5,
          maxLines: 12,
          onChanged: (v) {
            widget.onChanged(v);
            setState(() {}); // the preview follows the text
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Placeholders — click to insert at the cursor',
          style: context.text.smallMuted,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final v in resultVariables)
              _VariableChip(variable: v, onTap: () => _insert(v.name)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Preview (example run)', style: context.text.smallMuted),
        const SizedBox(height: AppSpacing.xs),
        AppPanel(
          color: c.surfaceMuted,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppSelectionArea(
            child: Text(
              renderResultTemplate(widget.controller.text, _example),
              style: context.text.monoSmall.copyWith(
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `{name}` with its meaning beside it; inserts the placeholder on click.
class _VariableChip extends StatelessWidget {
  const _VariableChip({required this.variable, required this.onTap});

  final ResultVariable variable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hovered ? c.surfaceHover : c.surfaceMuted,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: c.borderMuted),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '{${variable.name}}',
                style: context.text.monoSmall.copyWith(color: c.textPrimary),
              ),
              TextSpan(
                text: '  ${variable.description}',
                style: context.text.smallMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
