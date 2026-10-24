import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/database/database.dart';
import 'package:zml_lab/core/database/database_provider.dart';
import 'package:zml_lab/features/perf/application/sharegpt_dataset.dart';
import 'package:zml_lab/features/settings/application/settings_controller.dart';

void main() {
  test('refresh notices the file appearing and being deleted', () async {
    final tmp = Directory.systemTemp.createTempSync('sharegpt_dataset');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final file = File('${tmp.path}/sharegpt.json');

    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final sub = container.listen(shareGptDatasetProvider, (_, _) {});
    addTearDown(sub.close);

    // Let the settings load from the (empty) store before pointing it here.
    container.read(settingsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    container
        .read(settingsControllerProvider.notifier)
        .setPerfDatasetPath(file.path);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    DatasetPhase phase() => container.read(shareGptDatasetProvider).phase;
    final dataset = container.read(shareGptDatasetProvider.notifier);
    expect(phase(), DatasetPhase.missing);

    file.writeAsStringSync('[]');
    await dataset.refresh();
    expect(phase(), DatasetPhase.ready);

    // Deleted in Finder, say: the next look says so.
    file.deleteSync();
    await dataset.refresh();
    expect(phase(), DatasetPhase.missing);
  });
}
