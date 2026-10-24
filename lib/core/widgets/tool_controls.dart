import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_icon_button.dart';
import 'app_icons.dart';
import 'app_text_field.dart';
import 'hover_region.dart';
import 'surface.dart';

// The Benchmark tab's control kit, shared by its tools (benchmark, perf):
// labels above fields so a row's fields line up at the bottom, every control
// at exactly a text field's height, and a run button whose footprint never
// changes.

/// [child] with a small label above it. Stretches [child] to the width it's
/// given, so give it one (Expanded, or IntrinsicWidth).
class LabeledControl extends StatelessWidget {
  const LabeledControl({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.text.smallMuted,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// [child] stretched to exactly an [AppTextField]'s height (and as wide as
/// it is on its own), so a segmented control or button lines up with the
/// fields beside it. Measured, not assumed: a hidden field sets the height
/// (its intrinsic height overstates it, so no IntrinsicHeight).
class FieldHeight extends StatelessWidget {
  const FieldHeight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Width (intrinsic sizing included) comes from the child itself…
        Visibility.maintain(visible: false, child: child),
        // …height from a field.
        const Visibility.maintain(
          visible: false,
          child: SizedBox(width: 40, child: AppTextField(mono: true)),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// [field] with [trailing] (actions) beside it at exactly its height: the
/// field's row sets the height — a hidden copy of the actions reserves their
/// width — and the real actions are pinned over that slot. [trailing] gets
/// `stretch: true` for the pinned copy (fill the height) and `false` for the
/// sizing copy.
class FieldWithActions extends StatelessWidget {
  const FieldWithActions({
    super.key,
    required this.field,
    required this.actions,
  });

  final Widget field;
  final Widget Function({required bool stretch}) actions;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(child: field),
            const SizedBox(width: AppSpacing.md),
            Visibility.maintain(visible: false, child: actions(stretch: false)),
          ],
        ),
        Positioned(top: 0, bottom: 0, right: 0, child: actions(stretch: true)),
      ],
    );
  }
}

/// A tool's primary button and its Stop, in one footprint that never
/// changes: Stop shows beside the button while [running]; idle, the button
/// covers Stop's space too, so nothing shifts when a run starts. With
/// [stretch] both fill the height they're given (see [FieldWithActions]).
class RunActions extends StatelessWidget {
  const RunActions({
    super.key,
    required this.label,
    required this.icon,
    required this.running,
    required this.onRun,
    required this.onStop,
    this.stretch = false,
  });

  final String label;
  final IconData icon;
  final bool running;
  final VoidCallback? onRun;
  final VoidCallback onStop;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget button({bool fill = false}) => AppButton(
      label: label,
      icon: icon,
      variant: AppButtonVariant.primary,
      fill: fill,
      onPressed: onRun,
    );
    final both = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: stretch
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        button(),
        const SizedBox(width: AppSpacing.sm),
        Center(
          child: AppIconButton(
            icon: AppIcons.kill,
            size: 15,
            color: c.statusFailed,
            hoverColor: c.statusFailed,
            padding: const EdgeInsets.all(9),
            onPressed: onStop,
          ),
        ),
      ],
    );
    // The hidden sizing copy always reserves both.
    if (running || !stretch) return both;
    return Stack(
      children: [
        Visibility.maintain(visible: false, child: both),
        Positioned.fill(child: button(fill: true)),
      ],
    );
  }
}

/// A labelled field, label above — the parent sizes it. With [presets], a ▾
/// segment in the field opens a list of common values; typing any value
/// still works.
class SettingField extends StatefulWidget {
  const SettingField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.placeholder,
    this.presets,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final List<String>? presets;

  @override
  State<SettingField> createState() => _SettingFieldState();
}

class _SettingFieldState extends State<SettingField> {
  static const _segmentWidth = 34.0;

  final _link = LayerLink();
  final _menu = OverlayPortalController();

  void _pick(String value) {
    widget.controller.text = value;
    widget.onChanged(value);
    _menu.hide();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final presets = widget.presets;
    Widget field = AppTextField(
      controller: widget.controller,
      mono: true,
      placeholder: widget.placeholder,
      onChanged: widget.onChanged,
      // Keeps the text clear of the dropdown segment laid over the right.
      suffix: presets == null
          ? null
          : const SizedBox(width: _segmentWidth - AppSpacing.md + 4),
    );
    if (presets != null) {
      field = Stack(
        children: [
          field,
          // A split-button segment inside the field's border: its own tint,
          // a divider, and the full height clickable.
          Positioned(
            top: 1,
            bottom: 1,
            right: 1,
            width: _segmentWidth,
            child: HoverRegion(
              onTap: () => _menu.isShowing ? _menu.hide() : _menu.show(),
              builder: (context, hovered) => Container(
                decoration: BoxDecoration(
                  // One step up from the field's own fill — the same tone
                  // as the panels around it — so it reads as part of the
                  // control, not a separate grey block.
                  color: hovered ? c.surfaceHover : c.surface,
                  border: Border(left: BorderSide(color: c.borderMuted)),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(7),
                  ),
                ),
                child: Icon(
                  AppIcons.chevronDown,
                  size: 14,
                  color: hovered ? c.textPrimary : c.textMuted,
                ),
              ),
            ),
          ),
        ],
      );
      field = CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _menu,
          overlayChildBuilder: (context) => Stack(
            children: [
              // Tap outside to dismiss.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _menu.hide,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints.tightFor(
                      width: 120,
                    ).copyWith(maxHeight: 320),
                    child: AppPanel(
                      color: c.surface,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller,
                        builder: (context, value, _) => SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final p in presets)
                                _PresetRow(
                                  value: p,
                                  selected: value.text.trim() == p,
                                  onTap: () => _pick(p),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: field,
        ),
      );
    }
    return LabeledControl(label: widget.label, child: field);
  }
}

/// One value in a [SettingField]'s preset list.
class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: 0.12)
              : (hovered ? c.surfaceHover : null),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: context.text.mono.copyWith(
                  color: selected ? c.accent : c.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 12,
              child: selected
                  ? Icon(AppIcons.check, size: 12, color: c.accent)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
