import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/chart_trackball.dart';

void main() {
  testWidgets('a live chart keeps its trackball across updates', (
    tester,
  ) async {
    final seen = <TrackballBehavior>[];
    Widget chart(AppColors colors, int tick) => Directionality(
      textDirection: TextDirection.ltr,
      child: AppTheme(
        colors: colors,
        child: ChartTrackball(
          key: const ValueKey('chart'),
          builder: (context, trackball) {
            seen.add(trackball);
            return Text('$tick');
          },
        ),
      ),
    );

    // Data updates rebuild the chart: the same behavior, so the hover
    // readout isn't reset under the pointer.
    for (var tick = 0; tick < 3; tick++) {
      await tester.pumpWidget(chart(AppColors.dark, tick));
    }
    expect(seen, hasLength(3));
    expect(seen.toSet(), hasLength(1));

    // A theme switch restyles it.
    await tester.pumpWidget(chart(AppColors.light, 3));
    expect(identical(seen.last, seen.first), isFalse);
  });
}
