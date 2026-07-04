import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// A flat, custom-looking text input. Under the hood it uses a collapsed
/// [TextField] (wrapped in a transparent [Material]) purely so text is
/// properly selectable and editable — none of Material's visual chrome shows.
/// Supports a monospace mode and a leading prefix (e.g. `$`, `cd:`).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.prefix,
    this.mono = false,
    this.onChanged,
    this.onSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
    this.expands = false,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final String? prefix;
  final bool mono;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int minLines;
  final int maxLines;

  /// Fill the height of a bounded parent (e.g. an [Expanded]) instead of
  /// sizing to the text. Use for a full-height editor; overrides min/maxLines.
  final bool expands;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(
      () => setState(() => _focused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final baseStyle = widget.mono ? context.text.mono : context.text.body;
    final multiline = widget.maxLines > 1 || widget.expands;

    // A Container folds its border width into its effective padding, so the
    // thicker focus border would grow the box and nudge every widget laid out
    // around the field by a pixel or two. Trim the padding by the same delta so
    // the outer size stays put whether or not the field is focused.
    const focusBorder = 1.4;
    final borderWidth = _focused ? focusBorder : 1.0;
    final borderInset = focusBorder - borderWidth;

    return DefaultSelectionStyle(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.28),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md + borderInset,
          vertical: 11 + borderInset,
        ),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: _focused ? c.accent : c.border,
            width: borderWidth,
          ),
        ),
        child: Row(
          crossAxisAlignment: widget.expands
              ? CrossAxisAlignment.stretch
              : multiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (widget.prefix != null) ...[
              Text(
                widget.prefix!,
                style: context.text.monoSmall.copyWith(color: c.statusRunning),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Material(
                type: MaterialType.transparency,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  style: baseStyle,
                  cursorColor: c.accent,
                  cursorWidth: 1.6,
                  autofocus: widget.autofocus,
                  minLines: widget.expands ? null : widget.minLines,
                  maxLines: widget.expands ? null : widget.maxLines,
                  expands: widget.expands,
                  textAlignVertical: widget.expands
                      ? TextAlignVertical.top
                      : null,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.placeholder,
                    hintStyle: baseStyle.copyWith(color: c.textFaint),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
