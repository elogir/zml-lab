import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';

void main() {
  // A long preset list, opened from a field near the top of the window.
  Future<ScrollableState> openPresets(
    WidgetTester tester,
    double height,
  ) async {
    tester.view.physicalSize = Size(400, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
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
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: 160,
                      child: SettingField(
                        label: 'Concurrency',
                        controller: controller,
                        onChanged: (_) {},
                        presets: [for (var i = 1; i <= 20; i++) '$i'],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final field = tester.getRect(find.byType(AppTextField));
    await tester.tapAt(Offset(field.right - 8, field.center.dy));
    await tester.pumpAndSettle();
    return tester.stateList<ScrollableState>(find.byType(Scrollable)).last;
  }

  testWidgets('the presets show whole when the window has room', (
    tester,
  ) async {
    final menu = await openPresets(tester, 1000);
    expect(menu.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short window: the presets scroll, inside the window', (
    tester,
  ) async {
    final menu = await openPresets(tester, 300);
    expect(menu.position.maxScrollExtent, greaterThan(0));
    final box = tester.getRect(find.byType(Scrollable).last);
    expect(box.bottom, lessThanOrEqualTo(300));
    expect(tester.takeException(), isNull);
  });
}
