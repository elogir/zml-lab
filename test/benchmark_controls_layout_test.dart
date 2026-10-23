import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';
import 'package:zml_lab/features/benchmark/presentation/benchmark_view.dart';

void main() {
  // From the narrowest the terminal split allows to a full window.
  for (final width in [340.0, 520.0, 900.0]) {
    testWidgets('controls line up at ${width.toInt()} px', (tester) async {
      tester.view.physicalSize = Size(width, 800);
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
      // The visible button (the first is a hidden copy reserving its width).
      final send = rect(find.widgetWithText(AppButton, 'Send batch').last);

      // The number fields share a top edge and a height.
      expect(maxTokens.top, batch.top);
      expect(temp.top, batch.top);
      expect(maxTokens.height, batch.height);
      // Send is exactly as tall as the field beside it, on the same line.
      expect(send.top, model.top);
      expect(send.height, model.height);
      // Wide enough for a 4-digit batch size with room to spare.
      expect(batch.width, greaterThanOrEqualTo(80));
    });
  }
}
