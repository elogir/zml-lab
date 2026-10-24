import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';
import 'package:zml_lab/features/perf/application/sharegpt_dataset.dart';
import 'package:zml_lab/features/perf/domain/sharegpt.dart';
import 'package:zml_lab/features/perf/presentation/sharegpt_download_card.dart';

void main() {
  const path = '~/Library/Application Support/ZML-Lab/${ShareGpt.fileName}';

  Future<void> show(WidgetTester tester, DatasetState state) async {
    // As narrow as the tools get beside the terminal.
    tester.view.physicalSize = const Size(340, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppTheme(
          colors: AppColors.dark,
          child: Center(
            child: ShareGptDownloadCard(
              state: state,
              onDownload: () {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }

  testWidgets('first time: one download button', (tester) async {
    await show(
      tester,
      const DatasetState(phase: DatasetPhase.missing, path: path),
    );
    expect(find.text('Download ShareGPT'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(
      find.text('saved to ~/Library/Application Support/ZML-Lab'),
      findsOneWidget,
    );
  });

  testWidgets('downloading: progress, speed, time left, cancel', (
    tester,
  ) async {
    await show(
      tester,
      const DatasetState(
        phase: DatasetPhase.downloading,
        path: path,
        received: 336418971,
        total: ShareGpt.bytes,
        bytesPerSecond: 40e6,
      ),
    );
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('40.0 MB/s  ·  9 s left'), findsOneWidget);
    expect(find.text('336.4 MB of 672.8 MB'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('interrupted: resume from where it stopped', (tester) async {
    await show(
      tester,
      const DatasetState(
        phase: DatasetPhase.missing,
        path: path,
        received: 100000000,
        total: ShareGpt.bytes,
      ),
    );
    expect(find.text('Resume download'), findsOneWidget);
    expect(find.text('14%'), findsOneWidget);
  });

  testWidgets('failed: the reason and a retry', (tester) async {
    await show(
      tester,
      const DatasetState(
        phase: DatasetPhase.failed,
        path: path,
        received: 1000,
        total: ShareGpt.bytes,
        error: 'download failed: connection reset',
      ),
    );
    expect(find.text('download failed: connection reset'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Retry'), findsOneWidget);
  });
}
