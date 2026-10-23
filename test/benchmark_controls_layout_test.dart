import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';
import 'package:zml_lab/features/benchmark/presentation/benchmark_view.dart';

void main() {
  // From the narrowest the terminal split allows to a full window.
  // Short heights too: below a minimum the view scrolls, never overflows.
  for (final (width, height) in [
    (340.0, 800.0),
    (520.0, 800.0),
    (900.0, 800.0),
    (340.0, 420.0),
    (900.0, 420.0),
  ]) {
    testWidgets('controls line up at ${width.toInt()}x${height.toInt()}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: WidgetsApp(
            color: const Color(0xFF000000),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            builder: (context, _) => AppTheme(
              colors: AppColors.dark,
              child: const BenchmarkView(
                jobId: 'layout',
                jobName: 'x',
                jobDescription: '',
                jobCommand: '',
                machineName: 'local',
                endpoint: '127.0.0.1:8000',
                host: '127.0.0.1',
                port: 8000,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      // Fields in order: prompt, batch, max tokens, temp, model.
      final fields = find.byType(AppTextField);
      Rect rect(Finder f) => tester.getRect(f);
      final batch = rect(fields.at(1));
      final maxTokens = rect(fields.at(2));
      final temp = rect(fields.at(3));
      final model = rect(fields.at(4));
      // The visible button (the first is a hidden copy that sizes it).
      final send = rect(find.widgetWithText(AppButton, 'Send batch').last);

      // The settings share a top edge and a height.
      expect(temp.top, closeTo(maxTokens.top, 0.01));
      expect(model.top, closeTo(maxTokens.top, 0.01));
      expect(temp.height, closeTo(maxTokens.height, 0.01));
      expect(model.height, closeTo(maxTokens.height, 0.01));
      // Send is exactly as tall as the fields.
      expect(send.height, closeTo(model.height, 0.01));
      // Wide: Send sits on the settings' line and Model stays compact.
      if (width >= 600) {
        expect(send.top, closeTo(model.top, 0.01));
        expect(model.width, lessThanOrEqualTo(240));
      }
      // Batch fits a 4-digit size with room to spare, and every preset is
      // on screen.
      expect(batch.width, greaterThanOrEqualTo(80));
      for (final n in ['1', '8', '16', '32', '128', '512', '1024']) {
        // `.last`: the Batch field itself can show the same number.
        final chip = rect(find.text(n).last);
        expect(chip.right, lessThanOrEqualTo(width), reason: n);
      }
    });
  }
}
