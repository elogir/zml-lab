import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../theme/app_theme.dart';

/// Gives a chart one [TrackballBehavior] for its whole life (per theme), and
/// keeps the hover readout up while a live chart updates under a resting
/// pointer — with the new values.
///
/// Syncfusion hides the trackball on every data update (its series report a
/// range change each time) and otherwise freezes it at the values it was
/// shown with. So while the pointer rests on the chart those internal hides
/// are ignored — the last readout stays painted, no blank frame — and after
/// every rebuild the trackball is shown again where the pointer is. Pair it
/// with:
///  - `animationDuration: 0` on the series (the trackball skips a series
///    while it animates, and a series re-animates on every data change);
///  - axis maxima from [stableAxisMax], so the axes don't rescale on every
///    update.
class ChartTrackball extends StatefulWidget {
  const ChartTrackball({
    super.key,
    required this.builder,
    this.grouped = false,
  });

  final Widget Function(BuildContext context, TrackballBehavior trackball)
  builder;

  /// One readout listing every series, instead of one beside each point —
  /// for charts with more than a couple of series.
  final bool grouped;

  @override
  State<ChartTrackball> createState() => _ChartTrackballState();
}

class _ChartTrackballState extends State<ChartTrackball> {
  _LiveTrackball? _trackball;
  AppColors? _colors;

  /// Where the mouse rests over the chart (global), null when it isn't.
  Offset? _pointer;

  void _reshow() {
    final pointer = _pointer;
    final trackball = _trackball;
    if (!mounted || pointer == null || trackball == null) return;
    final box = trackball.parentBox;
    if (box == null || !box.attached || !box.hasSize) return;
    final local = box.globalToLocal(pointer);
    if (!(Offset.zero & box.size).contains(local)) return;
    trackball.show(local.dx, local.dy, 'pixel');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_trackball == null || !identical(c, _colors)) {
      _colors = c;
      _trackball = _LiveTrackball(
        pointerResting: () => _pointer != null,
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: widget.grouped
            ? TrackballDisplayMode.groupAllPoints
            : TrackballDisplayMode.floatAllPoints,
        lineColor: c.borderStrong,
        tooltipSettings: InteractiveTooltip(
          color: c.surface,
          textStyle: context.text.monoSmall.copyWith(color: c.textPrimary),
          borderColor: c.borderStrong,
          borderWidth: 1,
        ),
      );
    }
    // New data: once it's laid out, back under the pointer, fresh values.
    if (_pointer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reshow());
    }
    return MouseRegion(
      opaque: false,
      onHover: (e) => _pointer = e.position,
      onExit: (_) {
        _pointer = null;
        // Syncfusion's own exit may have come first and been ignored.
        _trackball?.hideNow();
      },
      child: widget.builder(context, _trackball!),
    );
  }
}

/// A trackball that ignores Syncfusion's hides while the pointer rests on
/// the chart (they come with every data update); [hideNow] really hides.
// TrackballBehavior is marked @immutable but keeps its own mutable state;
// this adds none.
// ignore: must_be_immutable
class _LiveTrackball extends TrackballBehavior {
  _LiveTrackball({
    required this.pointerResting,
    super.enable,
    super.activationMode,
    super.tooltipDisplayMode,
    super.lineColor,
    super.tooltipSettings,
  });

  final bool Function() pointerResting;

  @override
  void hide() {
    if (!pointerResting()) super.hide();
  }

  void hideNow() => super.hide();
}

/// An axis maximum for [value] that moves in coarse steps (1, 2, 2.5, 5 ×
/// 10ⁿ, with a little headroom) — a live chart's range then changes now and
/// then instead of on every update.
double stableAxisMax(double value) {
  if (value <= 0 || value.isNaN) return 1;
  final target = value * 1.05;
  final magnitude = math
      .pow(10, (math.log(target) / math.ln10).floor())
      .toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (m * magnitude >= target) return m * magnitude;
  }
  return 10 * magnitude;
}
