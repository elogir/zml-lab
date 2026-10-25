import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_checkbox.dart';
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

/// A field with its [label] above (none when null: the parent labels it) —
/// the parent sizes it. With [presets], a ▾ segment in the field opens a
/// list of common values; with [loadPresets], the ▾ fetches them instead,
/// filling the field directly when there's just one. Typing any value still
/// works.
class SettingField extends StatefulWidget {
  const SettingField({
    super.key,
    this.label,
    required this.controller,
    required this.onChanged,
    this.placeholder,
    this.presets,
    this.loadPresets,
    this.noPresets = 'none found',
  });

  final String? label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final List<String>? presets;
  final Future<List<String>> Function()? loadPresets;

  /// Shown in the menu when [loadPresets] finds nothing.
  final String noPresets;

  @override
  State<SettingField> createState() => _SettingFieldState();
}

class _SettingFieldState extends State<SettingField> {
  static const _segmentWidth = 34.0;

  final _link = LayerLink();
  final _menu = OverlayPortalController();

  /// What [SettingField.loadPresets] last found; null until it answers.
  List<String>? _loaded;
  bool _loading = false;

  void _pick(String value) {
    widget.controller.text = value;
    widget.onChanged(value);
    _menu.hide();
  }

  Future<void> _toggle() async {
    if (_menu.isShowing) return _menu.hide();
    final load = widget.loadPresets;
    if (load == null) return _menu.show();
    if (_loading) return;
    setState(() => _loading = true);
    final found = await load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loaded = found;
    });
    // Just one: nothing to choose.
    if (found.length == 1) {
      _pick(found.single);
    } else {
      _menu.show();
    }
  }

  /// The presets menu's height limit: the room between the field and the
  /// window's bottom edge, so the list scrolls only when the window is too
  /// short to show it all.
  double _menuMaxHeight(BuildContext overlay) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 320;
    final fieldBottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final room = MediaQuery.sizeOf(overlay).height - fieldBottom;
    // The menu's 4 px offset, and a margin above the window edge.
    return math.max(120, room - 4 - AppSpacing.md);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loads = widget.loadPresets != null;
    final presets = loads ? (_loaded ?? const <String>[]) : widget.presets;
    final hasMenu = loads || presets != null;
    // Loaded values (model names) are long: the menu is as wide as the field.
    final box = context.findRenderObject() as RenderBox?;
    final menuWidth = loads && box != null && box.hasSize
        ? math.max(120.0, box.size.width)
        : 120.0;
    Widget field = AppTextField(
      controller: widget.controller,
      mono: true,
      placeholder: widget.placeholder,
      onChanged: widget.onChanged,
      // Keeps the text clear of the dropdown segment laid over the right.
      suffix: hasMenu
          ? const SizedBox(width: _segmentWidth - AppSpacing.md + 4)
          : null,
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
              onTap: _toggle,
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
                  _loading ? AppIcons.refresh : AppIcons.chevronDown,
                  size: 14,
                  color: _loading
                      ? c.textFaint
                      : (hovered ? c.textPrimary : c.textMuted),
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
                    constraints: BoxConstraints.tightFor(
                      width: menuWidth,
                    ).copyWith(maxHeight: _menuMaxHeight(context)),
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
                              if (presets.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Text(
                                    widget.noPresets,
                                    style: context.text.smallMuted,
                                  ),
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
    final label = widget.label;
    return label == null ? field : LabeledControl(label: label, child: field);
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

/// A labelled checkbox (Warm-up, Ignore EOS), vertically centred in whatever
/// height it's given.
class CheckToggle extends StatelessWidget {
  const CheckToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      onTap: () => onChanged(!value),
      builder: (context, hovered) => Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        heightFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCheckbox(value: value, hovered: hovered),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: context.text.small, maxLines: 1),
          ],
        ),
      ),
    );
  }
}
