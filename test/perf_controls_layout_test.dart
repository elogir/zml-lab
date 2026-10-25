import 'package:drift/native.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/database/database.dart';
import 'package:zml_lab/core/database/database_provider.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';
import 'package:zml_lab/features/perf/presentation/perf_view.dart';

void main() {
  // From the narrowest the terminal split allows to a full window. Not right
  // at the breakpoints: the test font is much wider than Inter, so a width
  // that fits one line in the app (≥ 1360) overflows here until ~1550.
  for (final width in [340.0, 520.0, 900.0, 1600.0]) {
    testWidgets('perf controls line up at ${width.toInt()}', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: WidgetsApp(
            color: const Color(0xFF000000),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            builder: (context, _) => AppTheme(
              colors: AppColors.dark,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => const PerfView(
                      jobId: 'layout',
                      jobName: 'x',
                      jobDescription: '',
                      jobCommand: '',
                      machineName: 'local',
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
      await tester.pump();
      expect(tester.takeException(), isNull);

      Rect rect(Finder f) => tester.getRect(f);
      Rect labelled(String label) => rect(
        find
            .descendant(
              of: find.widgetWithText(LabeledControl, label),
              matching: find.byType(AppTextField),
            )
            .first,
      );
      Rect choice(String label) => rect(
        find
            .descendant(
              of: find.widgetWithText(LabeledControl, label),
              matching: find.byType(SegmentedControl<String>),
            )
            .last,
      );
      final duration = labelled('Duration (s)');
      final concurrency = labelled('Concurrency');
      final maxTokens = labelled('Max tokens');
      final model = labelled('Model');
      final prompts = choice('Prompts');
      final turns = choice('Turns');
      final run = rect(find.widgetWithText(AppButton, 'Run benchmark').last);

      // Every control is a field's height, and a row's controls share a top.
      for (final r in [concurrency, maxTokens, prompts, turns, run, model]) {
        expect(r.height, closeTo(duration.height, 0.01));
      }
      expect(concurrency.top, closeTo(duration.top, 0.01));
      expect(maxTokens.top, closeTo(duration.top, 0.01));
      // The run controls beside the model, or (narrowest) on a line under
      // it, the model field then a whole line wide.
      if (width >= 460) {
        expect(run.top, closeTo(model.top, 0.01));
        expect(run.left, greaterThan(model.right));
      } else {
        expect(run.top, greaterThan(model.bottom));
        expect(model.width, closeTo(width, 1));
      }
      if (width >= 1360) {
        // Everything on one line.
        for (final r in [prompts, turns, model]) {
          expect(r.top, closeTo(duration.top, 0.01));
        }
      } else if (width >= 650) {
        expect(prompts.top, closeTo(duration.top, 0.01));
        expect(model.top, greaterThan(duration.bottom));
      } else {
        expect(prompts.top, greaterThan(duration.bottom));
        expect(model.top, greaterThan(prompts.bottom));
      }
      // Duration at the left edge, numbers wide enough for 4 digits, and
      // the fullscreen button closing the row at the right edge.
      expect(duration.left, closeTo(0, 1));
      expect(duration.width, greaterThanOrEqualTo(width >= 650 ? 100 : 90));
      final fullscreen = rect(
        find
            .byWidgetPredicate(
              (w) => w is AppIconButton && w.icon == AppIcons.fullscreen,
            )
            .last, // the pinned copy, not the hidden sizing one
      );
      expect(fullscreen.right, closeTo(width, 1));
    });
  }
}
