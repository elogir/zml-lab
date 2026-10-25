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
import 'package:zml_lab/models/run_meta.dart';

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
    'server': {'version': '0.11.0'},
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
    expect(runMetaField(meta, 'hardware.description'), '1× RTX 4090');
    expect(runMetaField(meta, 'tags'), 'a, b');
    expect(runMetaField(meta, 'notes'), '');
  });

  test('edits merge into the meta, blanks remove their keys', () {
    final edited = withRunMetaFields(meta, {
      'label': '  llmd fp8  ',
      'server.commit': 'a1b2c3d',
      'server.version': '',
      'model.name': 'Qwen/Qwen3-8B-FP8',
      'hardware.description': '1× RTX 4090 (power-capped 300 W)',
      'tags': ' llmd, , fp8 ,',
      'notes': '',
    });
    expect(edited, {
      'schema_version': 1,
      'run_id': 'p-1',
      'label': 'llmd fp8',
      'tags': ['llmd', 'fp8'],
      'server': {'commit': 'a1b2c3d'},
      'model': {'name': 'Qwen/Qwen3-8B-FP8'},
      // What the dialog doesn't edit (the detected chips) is kept.
      'hardware': {
        'description': '1× RTX 4090 (power-capped 300 W)',
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

  test('only the fields whose trimmed text changed are written', () {
    expect(
      changedRunMetaFields(meta, {
        'label': ' vLLM · Qwen3-8B · c=16 ',
        'tags': 'a, b',
        'server.version': '0.11.1',
        'notes': '',
      }),
      {'server.version': '0.11.1'},
    );
  });

  test('a run file takes edited details, and still exports', () async {
    open.overrideFor(OperatingSystem.macOS, _libduckdb);
    final tmp = Directory.systemTemp.createTempSync('rewrite_meta_test');
    debugRunsDir = tmp.path;
    addTearDown(() {
      debugRunsDir = null;
      tmp.deleteSync(recursive: true);
    });
    final spool = await RunSpool.create('p-1');
    spool.addEvents(
      'timestamp,request_id,seq,token,request_timestamp,inputs_tokens,'
      'outputs_tokens,concurrency,server,session_id,error\n'
      '1000000300,c0-0,0,hi,1000000000,0,1,16,zml,s,\n',
    );
    final runFile = (await spool.finish(meta))!;
    final edited = withRunMetaFields(meta, {'notes': 'fp8 build'});
    await rewriteRunMeta(runFile, edited);
    expect(await readRunMeta(runFile), edited);
    final copy = '${tmp.path}/copy.zmlrun.parquet';
    await exportRun(runFile: runFile, meta: edited, out: copy);
    expect(File(copy).existsSync(), isTrue);
  }, skip: !File(_libduckdb).existsSync());

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
          // A saved run's name, as ZML-Lab shows it, goes over the file's.
          child: ExportRunDialog(
            runFile: runFile,
            overrides: const {'label': 'llmd fp8'},
          ),
        ),
      ),
    );
    // readRunMeta runs DuckDB on its own thread.
    for (
      var i = 0;
      i < 50 && find.text('Server commit').evaluate().isEmpty;
      i++
    ) {
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
    expect(text('Name'), 'llmd fp8');
    expect(text('Model'), 'Qwen/Qwen3-8B');
    expect(text('Server version'), '0.11.0');
    expect(text('Server commit'), '');
    expect(text('Tags'), 'a, b');
    // Prefilled with what was recorded, still editable.
    expect(text('Hardware'), '1× RTX 4090');
    expect(find.text('Quantization'), findsNothing);
    expect(find.byType(AppTextField), findsNWidgets(runMetaFields.length));
    expect(find.text('Export'), findsOneWidget);
  }, skip: !File(_libduckdb).existsSync());
}
