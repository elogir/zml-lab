import 'package:collection/collection.dart';

import '../../../core/util/search.dart';
import '../../../models/perf_report.dart';
import '../../../models/saved_benchmark.dart';

/// The Saved benchmarks tab's two kinds of runs.
enum SavedKind {
  perf,
  chat;

  String get label => switch (this) {
    SavedKind.perf => 'Perf',
    SavedKind.chat => 'Chat',
  };
}

/// A saved run of either kind, seen through one lens so the tab can filter,
/// sort, list and compare them alike.
sealed class SavedEntry {
  const SavedEntry();

  SavedKind get kind;
  String get id;
  String get name;
  String get machine;

  /// The model as shown: the alias given afterwards, else the one the
  /// requests named; empty when neither.
  String get model;
  DateTime get createdAt;

  /// Requests in flight at once: the perf run's concurrency, the chat
  /// batch's size.
  int get concurrency;

  /// The headline tok/s: the server's throughput (perf), the batch's
  /// aggregate (chat).
  double get throughput;

  /// Median time to first token in ms; null when the run has none.
  double? get ttftMs;

  /// The run's wall time.
  double get seconds;

  /// What else the search box looks through.
  Iterable<String?> get searchFields;

  bool matches(String query) =>
      matchesSearch(query, [name, machine, model, ...searchFields]);
}

class PerfEntry extends SavedEntry {
  const PerfEntry(this.report);

  final PerfReport report;

  @override
  SavedKind get kind => SavedKind.perf;
  @override
  String get id => report.id;
  @override
  String get name => report.name;
  @override
  String get machine => report.machineName;
  @override
  String get model => report.displayModel;
  @override
  DateTime get createdAt => report.createdAt;
  @override
  int get concurrency => report.params.concurrency;
  @override
  double get throughput => report.tokensPerSecond;
  @override
  double? get ttftMs => report.stat('Time to first token')?.p50;
  @override
  double get seconds => report.totalSeconds;

  /// The chips zml-smi saw (`4× NVIDIA GB300`), or null.
  String? get hardware => report.chips.isEmpty
      ? null
      : report.chips
            .groupListsBy((c) => c.name ?? c.kind)
            .entries
            .map((e) => '${e.value.length}× ${e.key}')
            .join(' + ');

  @override
  Iterable<String?> get searchFields => [
    report.endpoint,
    hardware,
    report.params.model,
    report.notes,
    report.benchCommand,
  ];
}

class ChatEntry extends SavedEntry {
  const ChatEntry(this.benchmark);

  final SavedBenchmark benchmark;

  @override
  SavedKind get kind => SavedKind.chat;
  @override
  String get id => benchmark.id;
  @override
  String get name => benchmark.name;
  @override
  String get machine => benchmark.machineLabel;
  @override
  String get model => benchmark.displayModel ?? '';
  @override
  DateTime get createdAt => benchmark.createdAt;
  @override
  int get concurrency => benchmark.batchSize;
  @override
  double get throughput => benchmark.aggregateTokensPerSecond;
  @override
  double? get ttftMs => benchmark.medianTtftMs.toDouble();
  @override
  double get seconds => benchmark.elapsedMs / 1000;

  @override
  Iterable<String?> get searchFields => [
    benchmark.endpoint,
    benchmark.model,
    benchmark.notes,
    benchmark.prompt,
  ];
}

/// A model name as lists show it: a local path is shortened to its last
/// segment (the model's folder); a hub id (`Qwen/Qwen3-8B`) stays whole.
String modelLabel(String model) {
  if (!model.startsWith('/') && !model.startsWith('~')) return model;
  final parts = model.split('/').where((p) => p.isNotEmpty);
  return parts.isEmpty ? model : parts.last;
}

/// What the list can be sorted by — the table's columns.
enum SavedSortKey {
  date,
  name,
  machine,
  model,
  concurrency,
  throughput,
  ttft,
  duration;

  /// The direction a column sorts in first: the newest and the fastest on
  /// top, everything else A→Z or smallest first.
  bool get descendingFirst =>
      this == SavedSortKey.date || this == SavedSortKey.throughput;
}

/// How the tab shows the runs.
enum SavedView { cards, table }

/// The tab's filters, sort and selection.
class SavedBrowse {
  const SavedBrowse({
    this.query = '',
    this.kind,
    this.machine,
    this.model,
    this.sortKey = SavedSortKey.date,
    this.descending = true,
    this.view = SavedView.cards,
    this.selected = const {},
  });

  final String query;

  /// Null = both kinds.
  final SavedKind? kind;

  /// Null = any machine.
  final String? machine;

  /// Null = any model.
  final String? model;
  final SavedSortKey sortKey;
  final bool descending;
  final SavedView view;

  /// Ids of the runs picked for Compare / Delete. Kept while the filters
  /// change, so runs from different machines can be picked together.
  final Set<String> selected;

  /// Whether a filter narrows the list (the search box aside).
  bool get narrowed => kind != null || machine != null || model != null;

  /// Whether anything narrows the list, the search box included.
  bool get filtered => narrowed || query.trim().isNotEmpty;

  static const _unset = Object();

  SavedBrowse copyWith({
    String? query,
    Object? kind = _unset,
    Object? machine = _unset,
    Object? model = _unset,
    SavedSortKey? sortKey,
    bool? descending,
    SavedView? view,
    Set<String>? selected,
  }) => SavedBrowse(
    query: query ?? this.query,
    kind: identical(kind, _unset) ? this.kind : kind as SavedKind?,
    machine: identical(machine, _unset) ? this.machine : machine as String?,
    model: identical(model, _unset) ? this.model : model as String?,
    sortKey: sortKey ?? this.sortKey,
    descending: descending ?? this.descending,
    view: view ?? this.view,
    selected: selected ?? this.selected,
  );

  bool accepts(SavedEntry e) =>
      (kind == null || e.kind == kind) &&
      (machine == null || e.machine == machine) &&
      (model == null || e.model == model) &&
      e.matches(query.trim());

  /// The runs these filters let through, in this sort's order.
  List<SavedEntry> apply(Iterable<SavedEntry> entries) =>
      entries.where(accepts).sorted(compare);

  /// Orders two runs by [sortKey] (newest first breaks ties).
  int compare(SavedEntry a, SavedEntry b) {
    // Runs without the value go last, whichever the direction.
    final aMissing = _missing(a);
    if (aMissing != _missing(b)) return aMissing ? 1 : -1;
    final byKey = aMissing
        ? 0
        : switch (sortKey) {
            SavedSortKey.date => a.createdAt.compareTo(b.createdAt),
            SavedSortKey.name => compareAsciiLowerCaseNatural(a.name, b.name),
            SavedSortKey.machine => compareAsciiLowerCaseNatural(
              a.machine,
              b.machine,
            ),
            SavedSortKey.model => compareAsciiLowerCaseNatural(
              modelLabel(a.model),
              modelLabel(b.model),
            ),
            SavedSortKey.concurrency => a.concurrency.compareTo(b.concurrency),
            SavedSortKey.throughput => a.throughput.compareTo(b.throughput),
            SavedSortKey.ttft => a.ttftMs!.compareTo(b.ttftMs!),
            SavedSortKey.duration => a.seconds.compareTo(b.seconds),
          };
    if (byKey != 0) return descending ? -byKey : byKey;
    return b.createdAt.compareTo(a.createdAt);
  }

  bool _missing(SavedEntry e) => switch (sortKey) {
    SavedSortKey.model => e.model.isEmpty,
    SavedSortKey.ttft => e.ttftMs == null,
    _ => false,
  };
}

/// A filter's choices: each distinct value among [entries] with how many
/// runs have it, most common first. Empty values aren't a choice.
List<(String, int)> facet(
  Iterable<SavedEntry> entries,
  String Function(SavedEntry) value,
) {
  final counts = <String, int>{};
  for (final e in entries) {
    final v = value(e);
    if (v.isNotEmpty) counts[v] = (counts[v] ?? 0) + 1;
  }
  return [for (final MapEntry(:key, :value) in counts.entries) (key, value)]
    ..sort((a, b) {
      final byCount = b.$2.compareTo(a.$2);
      return byCount != 0 ? byCount : compareAsciiLowerCaseNatural(a.$1, b.$1);
    });
}
