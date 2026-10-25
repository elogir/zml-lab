import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/perf_report.dart';
import '../../../models/run_meta.dart';
import '../../../models/saved_benchmark.dart';
import '../../../repositories/perf_report_repository.dart';
import '../../../repositories/saved_benchmark_repository.dart';
import '../../perf/domain/run_recorder.dart';
import '../../perf/domain/run_report.dart';
import '../domain/saved_entry.dart';

part 'saved_benchmarks_providers.g.dart';

@riverpod
Stream<List<SavedBenchmark>> savedBenchmarksStream(Ref ref) =>
    ref.watch(savedBenchmarkRepositoryProvider).watchBenchmarks();

@riverpod
Stream<List<PerfReport>> perfReportsStream(Ref ref) =>
    ref.watch(perfReportRepositoryProvider).watchReports();

/// What importing run files did ([SavedBrowser.importRuns]).
class RunImport {
  /// The runs saved, by name.
  final imported = <String>[];

  /// The runs already saved, skipped: their names.
  final duplicates = <String>[];

  /// The files that couldn't be imported, and why.
  final failed = <(String file, String reason)>[];
}

/// Every saved run, perf reports first, each kind newest first.
@riverpod
List<SavedEntry> savedEntries(Ref ref) => [
  for (final r in ref.watch(perfReportsStreamProvider).value ?? const [])
    PerfEntry(r),
  for (final b in ref.watch(savedBenchmarksStreamProvider).value ?? const [])
    ChatEntry(b),
];

/// The Saved benchmarks tab's filters, sort, view and selection — kept
/// while you're on other tabs.
@Riverpod(keepAlive: true)
class SavedBrowser extends _$SavedBrowser {
  @override
  SavedBrowse build() => const SavedBrowse();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setKind(SavedKind? kind) => state = state.copyWith(kind: kind);

  void setMachine(String? machine) => state = state.copyWith(machine: machine);

  void setModel(String? model) => state = state.copyWith(model: model);

  /// Back to every kind, machine and model (the search box has its own ×).
  void clearFilters() =>
      state = state.copyWith(kind: null, machine: null, model: null);

  void sort(SavedSortKey key, {required bool descending}) =>
      state = state.copyWith(sortKey: key, descending: descending);

  /// A column header's click: the same column flips direction, another
  /// starts in its own (see [SavedSortKey.descendingFirst]).
  void sortBy(SavedSortKey key) => sort(
    key,
    descending: key == state.sortKey ? !state.descending : key.descendingFirst,
  );

  void setView(SavedView view) => state = state.copyWith(view: view);

  void toggle(String id) => state = state.copyWith(
    selected: state.selected.contains(id)
        ? ({...state.selected}..remove(id))
        : {...state.selected, id},
  );

  /// Selects all of [ids], or — when they're all selected already — none
  /// of them.
  void toggleAll(Iterable<String> ids) {
    final all = ids.every(state.selected.contains);
    state = state.copyWith(
      selected: all
          ? state.selected.difference(ids.toSet())
          : {...state.selected, ...ids},
    );
  }

  void clearSelection() => state = state.copyWith(selected: const {});

  /// Saves the perf runs in [files] (`.zmlrun.parquet`), each file kept as
  /// its report's recording. A run already saved (the same `run_id`) is
  /// skipped; a file that can't be read is reported, and the rest go in.
  Future<RunImport> importRuns(Iterable<String> files) async {
    final repo = ref.read(perfReportRepositoryProvider);
    final result = RunImport();
    for (final file in files) {
      final name = file.split(RegExp(r'[/\\]')).last;
      final stem = name.replaceFirst(RegExp(r'(\.zmlrun)?\.parquet$'), '');
      try {
        final meta = await readRunMeta(file);
        if (meta == null) {
          throw const FormatException('no meta.json (zml.run): not a run file');
        }
        final id = meta['run_id'];
        // It names the file the run is kept in.
        if (id is! String || !RegExp(r'^\w[\w.-]*$').hasMatch(id)) {
          throw const FormatException('its meta.json has no usable run_id');
        }
        if (await repo.exists(id)) {
          final label = runMetaField(meta, 'label');
          result.duplicates.add(label.isEmpty ? stem : label);
          continue;
        }
        final rows = await readRunRows(file);
        if (rows.events.isEmpty) throw const FormatException('no events');
        final report = reportFromRun(
          meta,
          rows,
          fallbackName: stem,
          fallbackDate: DateTime.now(),
        );
        await keepRunFile(file, id);
        await repo.save(report);
        result.imported.add(report.name);
      } catch (e) {
        result.failed.add((
          name,
          e is FormatException
              ? e.message
              : '$e'.replaceFirst(RegExp(r'^\w*(Exception|Error): '), ''),
        ));
      }
    }
    return result;
  }

  /// Deletes [entries] (a perf report's recording with it) and drops them
  /// from the selection.
  Future<void> delete(Iterable<SavedEntry> entries) async {
    final list = entries.toList();
    state = state.copyWith(
      selected: state.selected.difference({for (final e in list) e.id}),
    );
    for (final e in list) {
      switch (e) {
        case PerfEntry(:final report):
          await ref.read(perfReportRepositoryProvider).delete(report.id);
          await deleteRun(report.id);
        case ChatEntry(:final benchmark):
          await ref.read(savedBenchmarkRepositoryProvider).delete(benchmark.id);
      }
    }
  }
}
