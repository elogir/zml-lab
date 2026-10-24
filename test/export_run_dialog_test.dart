import 'dart:io';

import 'package:dart_duckdb/dart_duckdb.dart' show OperatingSystem;
import 'package:dart_duckdb/open.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/widgets.dart';
import 'package:zml_lab/features/perf/domain/run_recorder.dart';
import 'package:zml_lab/features/perf/presentation/export_run_dialog.dart';

/// The DuckDB library the plugin downloads (flutter test runs without the
/// app, so the plugin's linked copy isn't there).
final _libduckdb =
    '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
    'dart_duckdb-1.4.4/macos/Libraries/release/libduckdb.dylib';

void main() {
  const meta = {
    'schema_version': 1,
    'run_id': 'p-1',
    'label': 'vLLM · Qwen3-8B · c=16',
    'tags': ['a', 'b'],
    'server': {'kind': 'vllm', 'version': '0.11.0'},
    'model': {'name': 'Qwen/Qwen3-8B'},
    'hardware': {
      'description': '1× RTX 4090',
      'chips': [
        {'device': 0, 'kind': 'cuda'},
      ],
    },
  };

  test('fields read from the meta by path', () {
    expect(runMetaField(meta, 'label'), 'vLLM · Qwen3-8B · c=16');
    expect(runMetaField(meta, 'server.version'), '0.11.0');
    expect(runMetaField(meta, 'server.commit'), '');
    expect(runMetaField(meta, 'model.quantization'), '');
    expect(runMetaField(meta, 'tags'), 'a, b');
    expect(runMetaField(meta, 'notes'), '');
  });

  test('edits merge into the meta, blanks remove their keys', () {
    final edited = withRunMetaFields(meta, {
      'label': '  llmd fp8  ',
      'server.commit': 'a1b2c3d',
      'server.version': '',
      'model.quantization': 'fp8',
      'hardware.description': '',
      'tags': ' llmd, , fp8 ,',
      'notes': '',
    });
    expect(edited, {
      'schema_version': 1,
      'run_id': 'p-1',
      'label': 'llmd fp8',
      'tags': ['llmd', 'fp8'],
      'server': {'kind': 'vllm', 'commit': 'a1b2c3d'},
      'model': {'name': 'Qwen/Qwen3-8B', 'quantization': 'fp8'},
      // What the dialog doesn't edit (detected chips) is kept.
      'hardware': {
        'chips': [
          {'device': 0, 'kind': 'cuda'},
        ],
      },
    });
    // The original is untouched.
    expect((meta['server'] as Map)['version'], '0.11.0');
    expect(withRunMetaFields(meta, {'tags': ''}).containsKey('tags'), isFalse);
    // A section the run didn't have is created.
    expect(withRunMetaFields(const {}, {'server.commit': 'x'}), {
      'server': {'commit': 'x'},
    });
  });

  testWidgets('the dialog opens prefilled from the run file', (tester) async {
    open.overrideFor(OperatingSystem.macOS, _libduckdb);
    final tmp = Directory.systemTemp.createTempSync('export_dialog_test');
    debugRunsDir = tmp.path;
    addTearDown(() {
      debugRunsDir = null;
      tmp.deleteSync(recursive: true);
    });
    final runFile = (await tester.runAsync(() async {
      final spool = await RunSpool.create('p-1');
      spool.addEvents(
        'timestamp,request_id,seq,token,request_timestamp,inputs_tokens,'
        'outputs_tokens,concurrency,server,session_id,error\n'
        '1000000300,c0-0,0,hi,1000000000,0,1,16,zml,s,\n',
      );
      return spool.finish(meta);
    }))!;

    tester.view.physicalSize = const Size(700, 900);
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
          child: ExportRunDialog(runFile: runFile),
        ),
      ),
    );
    // readRunMeta runs DuckDB on its own thread.
    for (var i = 0; i < 50 && find.text('Commit').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(tester.takeException(), isNull);

    String text(String label) => tester
        .widget<AppTextField>(
          find.descendant(
            of: find
                .ancestor(of: find.text(label), matching: find.byType(Column))
                .first,
            matching: find.byType(AppTextField),
          ),
        )
        .controller!
        .text;
    expect(text('Label'), 'vLLM · Qwen3-8B · c=16');
    expect(text('Model'), 'Qwen/Qwen3-8B');
    expect(text('Server version'), '0.11.0');
    expect(text('Commit'), '');
    expect(text('Hardware'), '1× RTX 4090');
    expect(text('Tags'), 'a, b');
    expect(find.text('Export…'), findsOneWidget);
  }, skip: !File(_libduckdb).existsSync());
}
