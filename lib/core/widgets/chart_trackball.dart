import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../theme/app_theme.dart';

/// Gives a chart one [TrackballBehavior] for its whole life (per theme), and
/// keeps the hover readout up while a live chart updates under a resting
/// pointer — with the new values.
///
/// Syncfusion hides the trackball whenever an axis range changes (a live
/// chart's does as data arrives) and otherwise freezes it at the values it
/// was shown with; so after every rebuild the trackball is shown again where
/// the pointer is. Pair it with:
///  - `animationDuration: 0` on the series (the trackball skips a series
///    while it animates, and a series re-animates on every data change);
///  - axis maxima from [stableAxisMax], so ranges (and those hides) change
///    rarely rather than on every update.
class ChartTrackball extends StatefulWidget {
  const ChartTrackball({super.key, required this.builder});

  final Widget Function(BuildContext context, TrackballBehavior trackball)
  builder;

  @override
  State<ChartTrackball> createState() => _ChartTrackballState();
}

class _ChartTrackballState extends State<ChartTrackball> {
  TrackballBehavior? _trackball;
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
      _trackball = TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
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
      onExit: (_) => _pointer = null,
      child: widget.builder(context, _trackball!),
    );
  }
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
