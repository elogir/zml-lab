import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';
import 'package:zml_lab/features/saved_benchmarks/application/saved_benchmarks_providers.dart';
import 'package:zml_lab/features/saved_benchmarks/presentation/saved_benchmarks_screen.dart';
import 'package:zml_lab/features/saved_benchmarks/presentation/saved_table.dart';

import 'fixtures/saved_runs.dart';

void main() {
  final reports = [
    perfReport(
      'gb300 qwen c64',
      model: 'Qwen/Qwen3-8B',
      concurrency: 64,
      tps: 3000,
      ttftP50: 400,
      createdAt: DateTime(2026, 10, 3),
    ),
    perfReport(
      'local llama',
      machine: 'local',
      model: '/Users/me/models/Llama-3.1-8B',
      tps: 500,
      ttftP50: 90,
      createdAt: DateTime(2026, 10, 2),
    ),
  ];
  final chats = [chatBenchmark('chat run', model: 'Qwen/Qwen3-8B')];

  Future<void> pump(WidgetTester tester, {double width = 1400}) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfReportsStreamProvider.overrideWith(
            (ref) => Stream.value(reports),
          ),
          savedBenchmarksStreamProvider.overrideWith(
            (ref) => Stream.value(chats),
          ),
        ],
        child: WidgetsApp(
          color: const Color(0xFF000000),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          builder: (context, child) =>
              AppTheme(colors: AppColors.dark, child: child!),
          home: const SavedBenchmarksScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('filters narrow the runs; clearing brings them back', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('gb300 qwen c64'), findsOneWidget);
    expect(find.text('local llama'), findsOneWidget);
    expect(find.text('chat run'), findsOneWidget);
    expect(find.text('3 runs'), findsOneWidget);

    await tester.tap(find.text('Any machine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('local').last);
    await tester.pumpAndSettle();
    expect(find.text('gb300 qwen c64'), findsNothing);
    expect(find.text('local llama'), findsOneWidget);
    expect(find.text('chat run'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('gb300 qwen c64'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('gb300 qwen c64'), findsNothing);
    expect(find.text('chat run'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [520.0, 900.0, 1400.0]) {
    testWidgets('the table fits at ${width.toInt()} and sorts by a header', (
      tester,
    ) async {
      await pump(tester, width: width);
      await tester.tap(find.byIcon(AppIcons.table));
      await tester.pumpAndSettle();
      expect(find.byType(SavedTable), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      double y(String name) => tester.getTopLeft(find.text(name)).dy;
      expect(y('gb300 qwen c64'), lessThan(y('local llama')));
      // Slowest first: tok/s's second click (its first is fastest first).
      await tester.tap(find.text('tok/s').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('tok/s').first);
      await tester.pumpAndSettle();
      expect(y('local llama'), lessThan(y('gb300 qwen c64')));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('two picked perf runs open side by side', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(AppIcons.table));
    await tester.pumpAndSettle();
    // The header check box picks the whole perf table.
    await tester.tap(find.byType(AppCheckbox).first);
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Compare'));
    await tester.pumpAndSettle();
    expect(find.text('Compare 2 perf reports'), findsOneWidget);
    // Oldest first: the local run (500 tok/s) is the baseline.
    expect(find.text('+500.0%'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The other run as the baseline turns the change around.
    await tester.tap(find.text('gb300 qwen c64').last);
    await tester.pumpAndSettle();
    expect(find.text('−83.3%'), findsOneWidget);
  });

  testWidgets('a mixed pick can\'t be compared', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(AppIcons.table));
    await tester.pumpAndSettle();
    final boxes = find.byType(AppCheckbox);
    // Rows: perf header, 2 perf runs, chat header, 1 chat run.
    await tester.tap(boxes.at(1));
    await tester.tap(boxes.at(4));
    await tester.pumpAndSettle();
    expect(find.text('compare one kind at a time'), findsOneWidget);
    // While picking, a row's click picks it too.
    await tester.tap(find.text('local llama'));
    await tester.pumpAndSettle();
    expect(find.text('3 selected'), findsOneWidget);
  });
}
