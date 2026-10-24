import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/widgets/smooth_live_series.dart';

typedef _P = ({int t, double v});

void main() {
  late List<_P> shown;

  Widget series(List<_P> points, {bool live = true}) => SmoothLiveSeries<_P>(
    points: points,
    live: live,
    timeMs: (p) => p.t,
    lerp: (a, b, f, at) => (t: at, v: a.v + (b.v - a.v) * f),
    builder: (context, s) {
      shown = s;
      return const SizedBox();
    },
  );

  final samples = <_P>[(t: 0, v: 0), (t: 100, v: 10), (t: 200, v: 30)];

  testWidgets('a finished series is shown as it is', (tester) async {
    await tester.pumpWidget(series(samples, live: false));
    expect(shown, samples);
  });

  testWidgets('live, the tip glides between samples every frame', (
    tester,
  ) async {
    await tester.pumpWidget(series(samples));
    // One sample behind the newest to start with.
    expect(shown.last, (t: 100, v: 10));

    // Frame by frame the tip moves on, values interpolated in between.
    final tips = <_P>[];
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      tips.add(shown.last);
    }
    for (var i = 1; i < tips.length; i++) {
      expect(tips[i].t, greaterThan(tips[i - 1].t), reason: 'frame $i');
    }
    final mid = tips.firstWhere((p) => p.t > 140 && p.t < 160);
    expect(mid.v, closeTo(10 + 20 * (mid.t - 100) / 100, 1e-9));

    // It waits at the newest sample when the next is late…
    await tester.pump(const Duration(milliseconds: 200));
    expect(shown.last, (t: 200, v: 30));
    expect(shown, samples);

    // …and carries on from there when it lands.
    await tester.pumpWidget(series([...samples, (t: 300, v: 30)]));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 40));
    expect(shown.last.t, inInclusiveRange(230, 260));
    expect(shown.last.v, 30);
  });

  testWidgets('far behind after a stall, it catches up', (tester) async {
    await tester.pumpWidget(series(samples));
    // A burst: a second of samples at once.
    await tester.pumpWidget(
      series([
        ...samples,
        for (var t = 300; t <= 1200; t += 100) (t: t, v: 30),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 16));
    // Within 300 ms of the newest, not crawling up from 100 ms.
    expect(shown.last.t, greaterThanOrEqualTo(900));
  });
}
