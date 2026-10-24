import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../theme/app_theme.dart';

/// Gives a chart one [TrackballBehavior] for its whole life (per theme), so
/// the hover readout survives the rebuilds of a live chart — a new instance
/// on every update would drop it. Hover shows it on desktop; a tap on touch.
///
/// Pair it with `animationDuration: 0` on the series: the trackball skips a
/// series while it animates, and a series re-animates on every data change,
/// so a live chart would never be readable.
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
    return widget.builder(context, _trackball!);
  }
}
