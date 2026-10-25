// The sidebar's download ring: it spins until progress arrives, then fills
// and stops ticking.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_colors.dart';
import 'package:zml_lab/core/widgets/progress_ring.dart';

Widget _ring(double progress) => Center(
  child: ProgressRing(
    progress: progress,
    color: AppColors.dark.accent,
    track: AppColors.dark.border,
  ),
);

void main() {
  testWidgets('spins until there is progress, then stops ticking', (
    tester,
  ) async {
    await tester.pumpWidget(_ring(0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(_ring(0.45));
    // Settles once the fill has eased in: the spinner no longer runs.
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_ring(1));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
