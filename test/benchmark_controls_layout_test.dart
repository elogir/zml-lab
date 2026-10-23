import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';
import 'package:zml_lab/features/benchmark/presentation/benchmark_view.dart';

void main() {
  // From the narrowest the terminal split allows to a full window, and short
  // windows too (below a minimum the view scrolls instead of overflowing).
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
            // An Overlay for the preset menu (the app's router provides one).
            builder: (context, _) => AppTheme(
              colors: AppColors.dark,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => const BenchmarkView(
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
                ],
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
      // The visible button (the first is a hidden copy reserving its width).
      final send = rect(find.widgetWithText(AppButton, 'Send batch').last);

      // The number fields share a top edge and a height.
      expect(maxTokens.top, closeTo(batch.top, 0.01));
      expect(temp.top, closeTo(batch.top, 0.01));
      expect(maxTokens.height, closeTo(batch.height, 0.01));
      // Send is exactly as tall as the field beside it, on the same line.
      expect(send.top, closeTo(model.top, 0.01));
      expect(send.height, closeTo(model.height, 0.01));
      // Wide: the model field stays compact, Send right after it.
      if (width >= 600) {
        expect(model.width, lessThanOrEqualTo(240));
        expect(send.left - model.right, lessThan(20));
      }
      // Room for a 4-digit batch size beside the preset chevron.
      expect(batch.width, greaterThanOrEqualTo(80));

      // The chevron opens the presets; picking one fills the field.
      await tester.ensureVisible(fields.at(1));
      await tester.tap(
        find.descendant(of: fields.at(1), matching: find.byType(AppIconButton)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('1024').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppTextField>(fields.at(1)).controller!.text,
        '1024',
      );
      expect(find.text('512'), findsNothing); // the menu closed
    });
  }
}
