import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';
import 'package:zml_lab/features/perf/application/sharegpt_dataset.dart';
import 'package:zml_lab/features/perf/domain/sharegpt.dart';
import 'package:zml_lab/features/perf/presentation/sharegpt_download_card.dart';

void main() {
  const path = '~/Library/Application Support/ZML-Lab/${ShareGpt.fileName}';
  const folder = '~/Library/Application Support/ZML-Lab';

  Future<int> show(WidgetTester tester, DatasetState state) async {
    var chose = 0;
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
            child: ShareGptDownload(
              state: state,
              folder: folder,
              onDownload: () {},
              onCancel: () {},
              onChooseFolder: () => chose++,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    if (find.text('Change folder…').evaluate().isNotEmpty) {
      await tester.tap(find.text('Change folder…'));
    }
    return chose;
  }

  testWidgets('first time: a button, the size and where it saves', (
    tester,
  ) async {
    final chose = await show(
      tester,
      const DatasetState(phase: DatasetPhase.missing, path: path),
    );
    expect(find.text('Download ShareGPT'), findsOneWidget);
    expect(find.text('673 MB  ·  to $folder'), findsOneWidget);
    expect(chose, 1); // Change folder… opens the folder picker
    // The path is shown whole (not cut short by the link), the link below.
    final where = tester.getRect(find.text('673 MB  ·  to $folder'));
    final link = tester.getRect(find.text('Change folder…'));
    expect(link.top, greaterThan(where.bottom));
    expect(
      tester.widget<Text>(find.text('673 MB  ·  to $folder')).overflow,
      isNull,
    );
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('downloading: one line of figures and a cancel', (tester) async {
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
    expect(
      find.text('50%  ·  336.4 MB of 672.8 MB  ·  40.0 MB/s  ·  9 s left'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is AppIconButton && w.icon == AppIcons.close,
      ),
      findsOneWidget,
    );
    // No folder change mid-download.
    expect(find.text('Change folder…'), findsNothing);
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
    expect(find.text('14%  ·  100.0 MB of 672.8 MB'), findsOneWidget);
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
