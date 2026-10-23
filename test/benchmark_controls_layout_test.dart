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
    (1400.0, 800.0),
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

      // Fields by what they are (their order changes with the layout).
      Finder field(bool Function(AppTextField f) test) =>
          find.byWidgetPredicate((w) => w is AppTextField && test(w)).first;
      Rect rect(Finder f) => tester.getRect(f);
      final batchField = field(
        (f) => f.prefix == null && f.placeholder == null && f.suffix != null,
      );
      final batch = rect(batchField);
      final maxTokens = rect(field((f) => f.placeholder == '∞'));
      final temp = rect(field((f) => f.placeholder == 'auto'));
      final model = rect(field((f) => f.placeholder == 'zml_model'));
      final prompt = rect(field((f) => f.prefix == '>'));
      // The visible button (the first is a hidden copy reserving its width).
      final send = rect(find.widgetWithText(AppButton, 'Send batch').last);

      // The number fields share a top edge and a height.
      expect(maxTokens.top, closeTo(batch.top, 0.01));
      expect(temp.top, closeTo(batch.top, 0.01));
      expect(maxTokens.height, closeTo(batch.height, 0.01));
      // Send is exactly as tall as the field beside it, on the same line.
      expect(send.top, closeTo(model.top, 0.01));
      expect(send.height, closeTo(model.height, 0.01));
      // Very wide: the prompt joins the settings' line at the same height.
      if (width >= 1150) {
        expect(prompt.top, closeTo(batch.top, 0.01));
        expect(prompt.height, closeTo(batch.height, 0.01));
      } else {
        expect(prompt.bottom, lessThan(batch.top));
      }
      // No trailing gap: Send ends where the row ends (the settings fill it).
      expect(send.right, closeTo(width, 1));
      // Send follows the prompt on the one-row layout, the model otherwise;
      // Batch always starts the settings at the left edge.
      final beforeSend = width >= 1150 ? prompt : model;
      expect(send.left - beforeSend.right, lessThan(20));
      expect(batch.left, closeTo(0, 1));
      // Room for a 4-digit batch size beside the dropdown segment (128 px
      // on one line; an equal share of the row when stacked).
      expect(batch.width, greaterThanOrEqualTo(width >= 600 ? 128 : 100));

      // Stats form a grid: every label starts at one of the first row's
      // column edges, whether they fit on one line or wrap.
      final stats = [
        'AGGREGATE',
        'AVG / REQ',
        'COMPLETED',
        'MEDIAN TTFT',
        'ELAPSED',
      ].map((t) => tester.getRect(find.text(t))).toList();
      final firstRow = stats.where((r) => r.top == stats.first.top).toList();
      // Packed from the left at a fixed pitch, not spread across the bar.
      if (firstRow.length > 1) {
        expect(firstRow[1].left - firstRow[0].left, closeTo(132, 0.5));
      }
      final columns = firstRow.map((r) => r.left).toList();
      for (final r in stats) {
        expect(
          columns.any((x) => (x - r.left).abs() < 0.5),
          isTrue,
          reason: 'stat at ${r.left} is off the column grid $columns',
        );
      }

      // The dropdown segment (the field's right end, full height) opens the
      // presets; picking one fills the field. Tapped near its bottom edge, so
      // this also checks the whole segment is the target.
      await tester.ensureVisible(batchField);
      final b = tester.getRect(batchField);
      await tester.tapAt(Offset(b.right - 8, b.bottom - 4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1024').last);
      await tester.pumpAndSettle();
      expect(tester.widget<AppTextField>(batchField).controller!.text, '1024');
      expect(find.text('512'), findsNothing); // the menu closed
    });
  }
}
