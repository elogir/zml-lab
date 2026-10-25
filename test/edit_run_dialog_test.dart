import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/features/saved_benchmarks/presentation/edit_run_dialog.dart';

void main() {
  testWidgets('the dialog edits the details; an alias equal to what was sent '
      'is dropped', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext context;
    await tester.pumpWidget(
      WidgetsApp(
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
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );

    const sent = '/models/Llama-3.1-8B';
    RunDetails? result;
    Future<void> open(RunDetails current) async {
      result = null;
      showEditRunDialog(
        context,
        current: current,
        sentModel: sent,
      ).then((r) => result = r);
      await tester.pumpAndSettle();
    }

    // The fields, in order: name, machine, model, notes.
    Finder field(int i) => find.byType(EditableText).at(i);
    String text(int i) => tester.widget<EditableText>(field(i)).controller.text;
    Future<void> save() async {
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    await open(const RunDetails(name: 'run', machine: 'local'));
    expect(text(2), sent);
    expect(find.textContaining('Sent as $sent'), findsOneWidget);
    await tester.enterText(field(0), 'llama bs4');
    await tester.enterText(field(1), 'GB300-1');
    await tester.enterText(field(2), 'Llama 3.1 8B');
    await tester.enterText(field(3), 'flash-attn on');
    await save();
    expect(result!.name, 'llama bs4');
    expect(result!.machine, 'GB300-1');
    expect(result!.modelAlias, 'Llama 3.1 8B');
    expect(result!.notes, 'flash-attn on');

    // Back to the sent name: no alias (same when the field is cleared).
    await open(result!);
    expect(text(2), 'Llama 3.1 8B');
    await tester.enterText(field(2), sent);
    await save();
    expect(result!.modelAlias, isNull);
    await open(result!);
    await tester.enterText(field(2), '');
    await save();
    expect(result!.modelAlias, isNull);

    // A name is required.
    await open(result!);
    await tester.enterText(field(0), '  ');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Give it a name.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
