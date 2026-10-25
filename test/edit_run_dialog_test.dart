import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/features/saved_benchmarks/presentation/edit_run_dialog.dart';
import 'package:zml_lab/models/run_meta.dart';
import 'package:zml_lab/models/saved_benchmark.dart';

void main() {
  testWidgets(
    'Edit details edits the meta.json fields under the shared rules',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
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
      const meta = {
        'run_id': 'p-1',
        'label': 'run',
        'model': {'name': sent},
        'hardware': {
          'description': '1× RTX 4090',
          'chips': [
            {'device': 0},
          ],
        },
        'tags': ['llmd'],
        'params': {'concurrency': 16},
      };
      Map<String, Object?>? result;
      Future<void> open(Map<String, Object?> meta) async {
        result = null;
        showEditRunDialog(
          context,
          meta: meta,
          sentModel: sent,
        ).then((r) => result = r);
        await tester.pumpAndSettle();
      }

      // The fields, in order: name, model, hardware, server version, server
      // commit, tags, notes.
      Finder field(int i) => find.byType(EditableText).at(i);
      String text(int i) =>
          tester.widget<EditableText>(field(i)).controller.text;
      Future<void> save() async {
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      }

      await open(meta);
      expect(
        [for (var i = 0; i < 7; i++) text(i)],
        ['run', sent, '1× RTX 4090', '', '', 'llmd', ''],
      );
      expect(find.textContaining('Sent as $sent'), findsOneWidget);
      await tester.enterText(field(0), ' llmd fp8 ');
      await tester.enterText(field(1), 'Llama 3.1 8B');
      await tester.enterText(field(3), '0.11.0');
      await tester.enterText(field(4), 'a1b2c3d');
      await tester.enterText(field(5), 'llmd, , fp8');
      await tester.enterText(field(6), 'flash-attn on');
      await save();
      expect(result, {
        'run_id': 'p-1',
        'label': 'llmd fp8',
        'model': {'name': 'Llama 3.1 8B'},
        // Untouched fields (the chips, the params) are kept as they were.
        'hardware': {
          'description': '1× RTX 4090',
          'chips': [
            {'device': 0},
          ],
        },
        'tags': ['llmd', 'fp8'],
        'params': {'concurrency': 16},
        'server': {'version': '0.11.0', 'commit': 'a1b2c3d'},
        'notes': 'flash-attn on',
      });

      // Cleared fields drop their key; a cleared Model goes back to what was
      // sent.
      await open(result!);
      await tester.enterText(field(1), '');
      await tester.enterText(field(5), '');
      await tester.enterText(field(6), '  ');
      await save();
      expect((result!['model'] as Map)['name'], sent);
      expect(result!.containsKey('tags'), isFalse);
      expect(result!.containsKey('notes'), isFalse);

      // A name is required.
      await open(result!);
      await tester.enterText(field(0), '  ');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Give it a name.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    },
  );

  test(
    'a chat run keeps its details; an alias equal to the sent model goes',
    () {
      final b = SavedBenchmark(
        id: 'b-1',
        name: 'run',
        endpoint: 'local:8000',
        prompt: 'hi',
        model: 'Qwen/Qwen3-8B',
        batchSize: 4,
        aggregateTokensPerSecond: 100,
        completed: 4,
        medianTtftMs: 100,
        elapsedMs: 2000,
        createdAt: DateTime(2026),
      );
      final edited = b.withDetails(
        RunDetails.fromMeta({
          ...b.details.toMeta(),
          'model': {'name': 'Qwen3 8B'},
          'server': {'commit': 'a1b2c3d'},
          'tags': ['fp8'],
        }),
      );
      expect(edited.displayModel, 'Qwen3 8B');
      expect(edited.model, 'Qwen/Qwen3-8B');
      expect(edited.serverCommit, 'a1b2c3d');
      expect(edited.tags, ['fp8']);
      expect(edited.details.toMeta(), {
        'label': 'run',
        'model': {'name': 'Qwen3 8B'},
        'server': {'commit': 'a1b2c3d'},
        'tags': ['fp8'],
      });
      final back = edited.withDetails(
        RunDetails.fromMeta({
          ...edited.details.toMeta(),
          'model': {'name': 'Qwen/Qwen3-8B'},
        }),
      );
      expect(back.modelAlias, isNull);
    },
  );
}
