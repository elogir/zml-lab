import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/database/database.dart';
import 'package:zml_lab/core/database/database_provider.dart';
import 'package:zml_lab/core/util/format.dart';
import 'package:zml_lab/features/perf/domain/run_recorder.dart';
import 'package:zml_lab/features/saved_benchmarks/application/saved_benchmarks_providers.dart';
import 'package:zml_lab/features/saved_benchmarks/domain/saved_entry.dart';
import 'package:zml_lab/features/saved_benchmarks/presentation/compare_view.dart';
import 'package:zml_lab/repositories/perf_report_repository.dart';
import 'package:zml_lab/repositories/saved_benchmark_repository.dart';

import 'fixtures/saved_runs.dart';

void main() {
  final entries = <SavedEntry>[
    PerfEntry(
      perfReport(
        'qwen-c64',
        model: 'Qwen/Qwen3-8B',
        concurrency: 64,
        tps: 3000,
        ttftP50: 400,
        createdAt: DateTime(2026, 10, 3),
      ),
    ),
    PerfEntry(
      perfReport(
        'llama-local',
        machine: 'local',
        model: '/Users/me/models/Llama-3.1-8B',
        tps: 500,
        ttftP50: 90,
        createdAt: DateTime(2026, 10, 2),
      ),
    ),
    // No TTFT row, no model.
    PerfEntry(perfReport('bare', tps: 800, createdAt: DateTime(2026, 10, 1))),
    ChatEntry(
      chatBenchmark(
        'chat',
        model: 'Qwen/Qwen3-8B',
        createdAt: DateTime(2026, 10, 4),
      ),
    ),
  ];
  List<String> ids(SavedBrowse b) => [for (final e in b.apply(entries)) e.id];

  group('filters', () {
    test('none: everything, newest first', () {
      expect(ids(const SavedBrowse()), [
        'chat',
        'qwen-c64',
        'llama-local',
        'bare',
      ]);
    });

    test('kind, machine and model narrow together', () {
      expect(ids(const SavedBrowse(kind: SavedKind.perf)), [
        'qwen-c64',
        'llama-local',
        'bare',
      ]);
      expect(ids(const SavedBrowse(machine: 'local')), ['chat', 'llama-local']);
      expect(ids(const SavedBrowse(model: 'Qwen/Qwen3-8B')), [
        'chat',
        'qwen-c64',
      ]);
      expect(
        ids(const SavedBrowse(kind: SavedKind.perf, model: 'Qwen/Qwen3-8B')),
        ['qwen-c64'],
      );
    });

    test('search matches every word, across fields', () {
      expect(ids(const SavedBrowse(query: 'llama local')), ['llama-local']);
      expect(ids(const SavedBrowse(query: 'qwen gb300')), ['qwen-c64']);
    });
  });

  group('sort', () {
    test('throughput: fastest first, then flipped', () {
      expect(ids(const SavedBrowse(sortKey: SavedSortKey.throughput)), [
        'qwen-c64',
        'bare',
        'llama-local',
        'chat',
      ]);
      expect(
        ids(
          const SavedBrowse(
            sortKey: SavedSortKey.throughput,
            descending: false,
          ),
        ),
        ['chat', 'llama-local', 'bare', 'qwen-c64'],
      );
    });

    test('a run without the value is last either way', () {
      const ttft = SavedBrowse(sortKey: SavedSortKey.ttft, descending: false);
      expect(ids(ttft).last, 'bare');
      expect(ids(ttft.copyWith(descending: true)).last, 'bare');
      const model = SavedBrowse(sortKey: SavedSortKey.model, descending: false);
      expect(ids(model).last, 'bare');
      expect(ids(model.copyWith(descending: true)).last, 'bare');
    });

    test('model sorts by the name shown (a path by its folder)', () {
      expect(
        ids(
          const SavedBrowse(
            kind: SavedKind.perf,
            sortKey: SavedSortKey.model,
            descending: false,
          ),
        ),
        ['llama-local', 'qwen-c64', 'bare'],
      );
    });
  });

  test('facets count each value, most common first, empties left out', () {
    expect(facet(entries, (e) => e.machine), [('GB300-1', 2), ('local', 2)]);
    expect(facet(entries, (e) => e.model), [
      ('Qwen/Qwen3-8B', 2),
      ('/Users/me/models/Llama-3.1-8B', 1),
    ]);
  });

  test('modelLabel shortens paths, keeps hub ids', () {
    expect(modelLabel('/Users/me/models/Llama-3.1-8B/'), 'Llama-3.1-8B');
    expect(modelLabel('~/models/Qwen3-8B'), 'Qwen3-8B');
    expect(modelLabel('Qwen/Qwen3-8B'), 'Qwen/Qwen3-8B');
  });

  test('formatWhen: relative for a week, then the day', () {
    // Clear of daylight-saving changes, which shift local day lengths.
    final now = DateTime(2026, 6, 25, 12);
    expect(formatWhen(DateTime(2026, 6, 25, 9), now: now), '3h ago');
    expect(formatWhen(DateTime(2026, 6, 19, 13), now: now), '5d ago');
    expect(formatWhen(DateTime(2026, 6, 12), now: now), 'Jun 12');
    expect(formatWhen(DateTime(2025, 3, 4), now: now), 'Mar 4, 2025');
  });

  test('the copied comparison shows changes against the baseline', () {
    final runs = [entries[0], entries[1]];
    final text = compareText(runs, 0);
    final throughput = text
        .split('\n')
        .firstWhere((l) => l.startsWith('Throughput'));
    expect(throughput, contains('3000.0 tok/s'));
    expect(throughput, contains('500.0 tok/s (−83.3%)'));
    final ttft = text.split('\n').firstWhere((l) => l.startsWith('TTFT p50'));
    expect(ttft, contains('400 ms  '));
    expect(ttft, contains('90 ms (−77.5%)'));
    // Against the other baseline, the first run carries the change.
    expect(
      compareText(
        runs,
        1,
      ).split('\n').firstWhere((l) => l.startsWith('Throughput')),
      contains('3000.0 tok/s (+500.0%)'),
    );
  });

  test('selection: toggle, all of a group, and delete', () async {
    final runs = await Directory.systemTemp.createTemp('saved_browse_test');
    debugRunsDir = runs.path;
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      debugRunsDir = null;
      container.dispose();
      await db.close();
      await runs.delete(recursive: true);
    });
    final reports = container.read(perfReportRepositoryProvider);
    final chats = container.read(savedBenchmarkRepositoryProvider);
    await reports.save(perfReport('p1'));
    await reports.save(perfReport('p2'));
    await chats.save(chatBenchmark('c1'));
    final recording = File(runFilePath('p1'))..createSync(recursive: true);

    final browser = container.read(savedBrowserProvider.notifier);
    browser.toggleAll(['p1', 'p2']);
    browser.toggle('c1');
    expect(container.read(savedBrowserProvider).selected, {'p1', 'p2', 'c1'});
    browser.toggleAll(['p1', 'p2']);
    expect(container.read(savedBrowserProvider).selected, {'c1'});

    browser.toggle('p1');
    await browser.delete([
      PerfEntry(perfReport('p1')),
      ChatEntry(chatBenchmark('c1')),
    ]);
    expect(container.read(savedBrowserProvider).selected, isEmpty);
    expect([for (final r in await reports.watchReports().first) r.id], ['p2']);
    expect(await chats.watchBenchmarks().first, isEmpty);
    expect(recording.existsSync(), isFalse);
  });

  test('edited details show and filter; what was measured stays', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final reports = DriftPerfReportRepository(db);
    const sent = '/Users/me/models/Llama-3.1-8B';
    final original = perfReport('p1', model: sent, tps: 1234);
    await reports.save(
      original.copyWith(
        name: 'llama c16',
        machineName: 'GB300-2',
        modelAlias: 'Llama 3.1 8B',
        notes: 'main @ 1a2b3c',
      ),
    );

    final back = (await reports.watchReports().first).single;
    expect(back.params.model, sent);
    expect(back.tokensPerSecond, 1234);
    expect(back.notes, 'main @ 1a2b3c');
    final entry = PerfEntry(back);
    expect(
      [entry.name, entry.machine, entry.model],
      ['llama c16', 'GB300-2', 'Llama 3.1 8B'],
    );
    // Search still finds what was sent, and the notes.
    expect(entry.matches('Llama-3.1-8B'), isTrue);
    expect(entry.matches('1a2b3c'), isTrue);
    // Without the alias, the sent model shows again.
    expect(PerfEntry(back.copyWith(modelAlias: null)).model, sent);
  });
}
