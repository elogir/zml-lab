import 'dart:io';

import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/features/perf/domain/csv_events.dart';
import 'package:zml_lab/features/perf/domain/perf_stats.dart';
import 'package:zml_lab/features/perf/presentation/perf_report_view.dart';
import 'package:zml_lab/models/perf_report.dart';

void main() {
  final csv = File('test/fixtures/perf_events.csv').readAsStringSync();
  final acc = PerfAccumulator()..addAll(PerfCsvParser().add(csv));
  final report = PerfReport(
    id: 'layout',
    name: 'layout',
    jobName: 'layout',
    machineName: 'local',
    endpoint: '127.0.0.1:8000',
    jobCommand: '',
    benchCommand: '',
    server: acc.server,
    createdAt: DateTime(2026),
    params: const PerfParams(),
    totalSeconds: acc.totalSeconds,
    totalEvents: acc.eventCount,
    totalRequests: acc.requestCount,
    tokensPerSecond: acc.tokensPerSecond,
    requestsPerSecond: acc.requestsPerSecond,
    maxSeq: acc.maxSeq,
    errorCount: acc.errorCount,
    stats: acc.statRows(),
    series: acc.series(includeLast: true),
    ttftHistogram: acc.ttftHistogram(),
    itlHistogram: acc.itlHistogram(),
  );

  // From the narrowest the terminal split allows (the tools pane's floor,
  // minus its padding) up.
  for (final width in [300.0, 340.0, 420.0, 520.0, 700.0]) {
    testWidgets('the report fits at ${width.toInt()}', (tester) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        WidgetsApp(
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
                  builder: (context) => PerfReportView(report: report),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  }
}
