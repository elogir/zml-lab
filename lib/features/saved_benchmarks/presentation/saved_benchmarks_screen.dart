import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../perf/presentation/perf_report_detail.dart';
import '../application/saved_benchmarks_providers.dart';
import '../domain/saved_entry.dart';
import 'compare_view.dart';
import 'saved_benchmark_detail.dart';
import 'saved_table.dart';

/// Opens a saved run's detail popup.
void openSavedEntry(BuildContext context, SavedEntry entry) => switch (entry) {
  PerfEntry(:final report) => showPerfReportDetail(context, report),
  ChatEntry(:final benchmark) => showSavedBenchmarkDetail(context, benchmark),
};

/// A run's tap: while runs are being picked it toggles this one too,
/// otherwise it opens the run.
void tapSavedEntry(BuildContext context, WidgetRef ref, SavedEntry entry) {
  if (ref.read(savedBrowserProvider).selected.isEmpty) {
    openSavedEntry(context, entry);
  } else {
    ref.read(savedBrowserProvider.notifier).toggle(entry.id);
  }
}

class SavedBenchmarksScreen extends ConsumerWidget {
  const SavedBenchmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(savedEntriesProvider);
    final browse = ref.watch(savedBrowserProvider);
    final shown = browse.apply(all);
    final reports = [
      for (final e in shown)
        if (e is PerfEntry) e,
    ];
    final benchmarks = [
      for (final e in shown)
        if (e is ChatEntry) e,
    ];
    // Group labels only earn their place when both kinds are present.
    final labelled = reports.isNotEmpty && benchmarks.isNotEmpty;
    final table = browse.view == SavedView.table;

    Widget group(SavedKind kind, List<SavedEntry> entries) => table
        ? SavedTable(kind: kind, entries: entries)
        : _CardGrid(entries: entries);

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(
            title: 'Saved benchmarks',
            subtitle:
                'Named snapshots of past runs — chat benchmarks and perf reports.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _FilterBar(all: all, shown: shown.length),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: shown.isEmpty
                      ? _EmptyState(filtered: all.isNotEmpty && browse.filtered)
                      : SingleChildScrollView(
                          // Room to scroll the last row clear of the
                          // selection bar.
                          padding: EdgeInsets.only(
                            bottom: browse.selected.isEmpty ? 0 : 72,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (reports.isNotEmpty) ...[
                                if (labelled) ...[
                                  const SectionLabel('PERF REPORTS'),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                group(SavedKind.perf, reports),
                              ],
                              if (labelled)
                                const SizedBox(height: AppSpacing.xl),
                              if (benchmarks.isNotEmpty) ...[
                                if (labelled) ...[
                                  const SectionLabel('CHAT BENCHMARKS'),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                group(SavedKind.chat, benchmarks),
                              ],
                            ],
                          ),
                        ),
                ),
                if (browse.selected.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(child: _SelectionBar(all: all)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Search, the filters, the result count, sort and view.
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.all, required this.shown});

  final List<SavedEntry> all;
  final int shown;

  static const _sorts = [
    (SavedSortKey.date, true, 'Newest first'),
    (SavedSortKey.date, false, 'Oldest first'),
    (SavedSortKey.throughput, true, 'Fastest first'),
    (SavedSortKey.ttft, false, 'Lowest TTFT first'),
    (SavedSortKey.name, false, 'Name'),
    (SavedSortKey.machine, false, 'Machine'),
    (SavedSortKey.model, false, 'Model'),
    (SavedSortKey.concurrency, false, 'Concurrency'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browse = ref.watch(savedBrowserProvider);
    final browser = ref.read(savedBrowserProvider.notifier);
    // A filter offers what the other kind-narrowed runs have.
    final ofKind = browse.kind == null
        ? all
        : [
            for (final e in all)
              if (e.kind == browse.kind) e,
          ];
    final machines = facet(ofKind, (e) => e.machine);
    final models = facet(ofKind, (e) => e.model);
    final sort = (browse.sortKey, browse.descending);
    final sortLabel =
        _sorts.where((s) => (s.$1, s.$2) == sort).firstOrNull?.$3 ??
        '${sortColumnLabel(browse.sortKey)} ${browse.descending ? '↓' : '↑'}';

    final filters = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PillTabs<SavedKind?>(
          options: [
            const SegmentOption(value: null, label: 'All'),
            for (final k in SavedKind.values)
              SegmentOption(value: k, label: k.label),
          ],
          value: browse.kind,
          onChanged: browser.setKind,
        ),
        _FacetMenu(
          noun: 'machine',
          icon: AppIcons.machines,
          values: machines,
          value: browse.machine,
          onSelected: browser.setMachine,
        ),
        _FacetMenu(
          noun: 'model',
          icon: AppIcons.model,
          values: models,
          value: browse.model,
          label: modelLabel,
          onSelected: browser.setModel,
        ),
        if (browse.narrowed)
          AppButton(
            label: 'Clear filters',
            icon: AppIcons.clearFilters,
            variant: AppButtonVariant.ghost,
            dense: true,
            onPressed: browser.clearFilters,
          ),
      ],
    );
    final count = Text(
      browse.filtered && shown != all.length
          ? '$shown of ${all.length}'
          : '${all.length} ${all.length == 1 ? 'run' : 'runs'}',
      style: context.text.smallMuted,
    );
    final sorter = AppMenuButton<(SavedSortKey, bool)>(
      icon: AppIcons.sort,
      label: sortLabel,
      value: sort,
      items: [
        for (final (key, descending, label) in _sorts)
          AppMenuItem(value: (key, descending), label: label),
      ],
      onSelected: (s) => browser.sort(s.$1, descending: s.$2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                hintText: 'Search names, machines, models, tags, notes',
                initialValue: browse.query,
                onChanged: browser.setQuery,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _ViewToggle(value: browse.view, onChanged: browser.setView),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // The count and sort sit at the right of the filters, or (narrow)
        // on a line of their own under them.
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 640
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    filters,
                    const SizedBox(height: AppSpacing.sm),
                    Row(children: [count, const Spacer(), sorter]),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: filters),
                    const SizedBox(width: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: count,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    sorter,
                  ],
                ),
        ),
      ],
    );
  }
}

/// A filter's drop-down: any, or one of [values] (with their counts).
class _FacetMenu extends StatelessWidget {
  const _FacetMenu({
    required this.noun,
    required this.icon,
    required this.values,
    required this.value,
    required this.onSelected,
    this.label = _same,
  });

  final String noun;
  final IconData icon;
  final List<(String, int)> values;
  final String? value;
  final ValueChanged<String?> onSelected;
  final String Function(String) label;

  static String _same(String s) => s;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return AppMenuButton<String?>(
      icon: icon,
      label: v == null ? 'Any $noun' : label(v),
      active: v != null,
      value: v,
      menuWidth: 320,
      items: [
        AppMenuItem(value: null, label: 'Any $noun'),
        for (final (name, count) in values)
          AppMenuItem(value: name, label: label(name), detail: '$count'),
        // A filter set on runs since deleted (or now of the other kind)
        // still shows, so it can be cleared.
        if (v != null && !values.any((e) => e.$1 == v))
          AppMenuItem(value: v, label: label(v), detail: '0'),
      ],
      onSelected: onSelected,
    );
  }
}

/// Cards or a table.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.value, required this.onChanged});

  final SavedView value;
  final ValueChanged<SavedView> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget option(SavedView view, IconData icon) => HoverRegion(
      onTap: () => onChanged(view),
      builder: (context, hovered) {
        final selected = view == value;
        return Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selected ? c.surfaceSelected : null,
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(
            icon,
            size: 15,
            color: selected || hovered ? c.textPrimary : c.textMuted,
          ),
        );
      },
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(SavedView.cards, AppIcons.cards),
          option(SavedView.table, AppIcons.table),
        ],
      ),
    );
  }
}

/// What's picked, and what can be done with it.
class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({required this.all});

  final List<SavedEntry> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final ids = ref.watch(savedBrowserProvider.select((b) => b.selected));
    final browser = ref.read(savedBrowserProvider.notifier);
    final picked = [
      for (final e in all)
        if (ids.contains(e.id)) e,
    ];
    final kinds = {for (final e in picked) e.kind};
    final why = switch (picked.length) {
      < 2 => 'pick another to compare',
      > maxCompared => 'compare up to $maxCompared',
      _ when kinds.length > 1 => 'compare one kind at a time',
      _ => null,
    };

    Future<void> delete() async {
      final n = picked.length;
      final ok = await showConfirmDialog(
        context,
        title: 'Delete $n saved ${n == 1 ? 'run' : 'runs'}?',
        message: kinds.contains(SavedKind.perf)
            ? 'Perf runs go with their recordings. This can\'t be undone.'
            : 'This can\'t be undone.',
        confirmLabel: 'Delete',
        icon: AppIcons.delete,
      );
      if (ok) await browser.delete(picked);
    }

    return AppPanel(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      border: Border.all(color: c.borderStrong),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${picked.length} selected', style: context.text.bodyStrong),
          if (why != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(why, style: context.text.smallMuted),
          ],
          const SizedBox(width: AppSpacing.lg),
          AppButton(
            label: 'Compare',
            icon: AppIcons.compare,
            variant: AppButtonVariant.primary,
            dense: true,
            onPressed: why == null ? () => showCompare(context, picked) : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: 'Delete',
            icon: AppIcons.delete,
            dense: true,
            onPressed: delete,
          ),
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            icon: AppIcons.close,
            size: 14,
            onPressed: browser.clearSelection,
          ),
        ],
      ),
    );
  }
}

class _CardGrid extends ConsumerWidget {
  const _CardGrid({required this.entries});

  final List<SavedEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(savedBrowserProvider.select((b) => b.selected));
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.lg;
        // One column when two would squeeze the cards' metrics.
        final width = constraints.maxWidth < 760
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final e in entries)
              SizedBox(
                width: width,
                child: switch (e) {
                  PerfEntry() => _PerfReportCard(
                    entry: e,
                    selected: selected.contains(e.id),
                  ),
                  ChatEntry() => _BenchmarkCard(
                    entry: e,
                    selected: selected.contains(e.id),
                  ),
                },
              ),
          ],
        );
      },
    );
  }
}

class _PerfReportCard extends ConsumerWidget {
  const _PerfReportCard({required this.entry, required this.selected});

  final PerfEntry entry;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final r = entry.report;
    final browser = ref.read(savedBrowserProvider.notifier);
    final ttft = entry.ttftMs;

    return AppCard(
      selected: selected,
      onTap: () => tapSavedEntry(context, ref, entry),
      onSelect: () => browser.toggle(r.id),
      onDelete: () => browser.delete([entry]),
      topRight: Text(formatWhen(r.createdAt), style: context.text.smallMuted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 72),
            child: Row(
              children: [
                Icon(AppIcons.perf, size: 12, color: c.textFaint),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    r.name,
                    style: context.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Where(
            machine: r.endpoint,
            model: entry.model,
            trailing: 'c ${r.params.concurrency}',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                r.tokensPerSecond.toStringAsFixed(1),
                style: context.text.mono.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.statusRunning,
                ),
              ),
              const SizedBox(width: 4),
              Text('tok/s', style: context.text.monoSmall),
              const SizedBox(width: AppSpacing.lg),
              _Metrics([
                _Metric(
                  label: 'req/s',
                  value: r.requestsPerSecond.toStringAsFixed(2),
                ),
                if (ttft != null)
                  _Metric(label: 'ttft p50', value: '${ttft.round()}ms'),
                _Metric(
                  label: 'dur',
                  value: '${r.totalSeconds.toStringAsFixed(0)}s',
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenchmarkCard extends ConsumerWidget {
  const _BenchmarkCard({required this.entry, required this.selected});

  final ChatEntry entry;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final b = entry.benchmark;
    final browser = ref.read(savedBrowserProvider.notifier);

    return AppCard(
      selected: selected,
      onTap: () => tapSavedEntry(context, ref, entry),
      onSelect: () => browser.toggle(b.id),
      onDelete: () => browser.delete([entry]),
      topRight: Text(formatWhen(b.createdAt), style: context.text.smallMuted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave room on the right for the top-right timestamp, which the
          // hover buttons replace.
          Padding(
            padding: const EdgeInsets.only(right: 72),
            child: Text(
              b.name,
              style: context.text.body.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Where(
            machine: '${b.machineLabel} ${b.portLabel}',
            model: entry.model,
            trailing: 'batch ${b.batchSize}',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                b.aggregateTokensPerSecond.toStringAsFixed(1),
                style: context.text.mono.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.statusRunning,
                ),
              ),
              const SizedBox(width: 4),
              Text('tok/s agg', style: context.text.monoSmall),
              const SizedBox(width: AppSpacing.lg),
              _Metrics([
                _Metric(
                  label: 'avg',
                  value: '${b.averageTokensPerSecond.toStringAsFixed(1)} t/s',
                ),
                _Metric(label: 'ttft', value: '${b.medianTtftMs}ms'),
                _Metric(
                  label: 'elapsed',
                  value: '${(b.elapsedMs / 1000).toStringAsFixed(1)}s',
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

/// A card's second line: where it ran, the model (when known), and the
/// load ([trailing]).
class _Where extends StatelessWidget {
  const _Where({
    required this.machine,
    required this.model,
    required this.trailing,
  });

  final String machine;
  final String model;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(AppIcons.machines, size: 12, color: c.textFaint),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            machine,
            style: context.text.monoSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (model.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.md),
          Icon(AppIcons.model, size: 12, color: c.textFaint),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              modelLabel(model),
              style: context.text.monoSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.md),
        Text(trailing, style: context.text.smallMuted),
      ],
    );
  }
}

/// A card's secondary metrics, right-aligned after the headline number;
/// they wrap under each other rather than overflow a narrow card.
class _Metrics extends StatelessWidget {
  const _Metrics(this.metrics);

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        children: metrics,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: context.text.monoSmall.copyWith(color: c.textFaint)),
        const SizedBox(width: 5),
        Text(value, style: context.text.monoSmall),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.filtered = false});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.savedBenchmarks, size: 26, color: c.textFaint),
          const SizedBox(height: AppSpacing.md),
          Text(
            filtered ? 'No matching benchmarks' : 'No saved benchmarks',
            style: context.text.bodySecondary,
          ),
          const SizedBox(height: 4),
          Text(
            filtered
                ? 'Try a different search or filter.'
                : 'Run a benchmark, then Save it to keep it here.',
            style: context.text.smallMuted,
          ),
        ],
      ),
    );
  }
}
