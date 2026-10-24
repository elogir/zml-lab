import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/chart_trackball.dart';
import 'package:zml_lab/features/perf/presentation/perf_charts.dart';
import 'package:zml_lab/models/perf_report.dart';

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

  testWidgets('a resting pointer keeps the readout up, with new values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A live run: one more second of data per update, rate climbing (so
    // both axes' ranges change along the way).
    List<PerfSeriesPoint> upTo(int seconds) => [
      for (var s = 0; s <= seconds; s++)
        PerfSeriesPoint(
          elapsedMs: s * 1000,
          tps: 100.0 * s,
          active: 4,
          requests: s,
        ),
    ];
    Widget chart(int seconds) => Directionality(
      textDirection: TextDirection.ltr,
      child: AppTheme(
        colors: AppColors.dark,
        child: Center(
          child: SizedBox(
            width: 500,
            height: 200,
            child: PerfSeriesChart(
              series: upTo(seconds),
              value: (s) => s.tps,
              color: const Color(0xFF00AA00),
            ),
          ),
        ),
      ),
    );
    TrackballBehavior trackball() => tester
        .widget<SfCartesianChart>(find.byType(SfCartesianChart))
        .trackballBehavior!;

    await tester.pumpWidget(chart(4));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    // Rest mid-chart.
    final origin = tester.getTopLeft(find.byType(SfCartesianChart));
    await mouse.moveTo(origin + const Offset(280, 100));
    await tester.pump();
    expect(trackball().chartPointInfo, isNotEmpty);
    final before = trackball().chartPointInfo.first.label;

    // Updates keep coming; the pointer doesn't move. Checked as each frame
    // was painted — before ChartTrackball's post-frame refresh (this
    // callback is registered first) — so a one-frame blank would show.
    final blank = <int>[];
    for (final seconds in [5, 6, 7, 8, 12, 20, 40]) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (trackball().chartPointInfo.isEmpty) blank.add(seconds);
      });
      await tester.pumpWidget(chart(seconds));
    }
    await tester.pump();
    expect(blank, isEmpty, reason: 'frames painted without the readout');
    // Let the axis finish easing to its new range.
    await tester.pump(const Duration(milliseconds: 300));
    // The axis stretched under the pointer: it now reads a later point.
    expect(trackball().chartPointInfo.first.label, isNot(before));

    // Leaving the chart hides it.
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(trackball().chartPointInfo, isEmpty);
  });

  test('axis maxima move in coarse steps, with headroom', () {
    expect(stableAxisMax(0), 1);
    expect(stableAxisMax(940), 1000);
    expect(stableAxisMax(960), 2000);
    expect(stableAxisMax(180), 200);
    expect(stableAxisMax(230), 250);
    expect(stableAxisMax(16), 20);
    // Many live values share a maximum, so the range rarely changes.
    expect(
      {for (var v = 400.0; v < 900; v += 10) stableAxisMax(v)},
      {500.0, 1000.0},
    );
  });
}
