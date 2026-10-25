import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/widgets.dart';
import '../application/saved_benchmarks_providers.dart';
import '../domain/saved_entry.dart';
import 'saved_benchmarks_screen.dart';

/// A sort's name when it's none of the sort menu's presets.
String sortColumnLabel(SavedSortKey key) => switch (key) {
  SavedSortKey.date => 'Saved',
  SavedSortKey.name => 'Name',
  SavedSortKey.machine => 'Machine',
  SavedSortKey.model => 'Model',
  SavedSortKey.concurrency => 'Concurrency',
  SavedSortKey.throughput => 'tok/s',
  SavedSortKey.ttft => 'TTFT',
  SavedSortKey.duration => 'Duration',
};

const double _rowHeight = 36;
const double _checkWidth = 34;
const double _actionWidth = 30;

/// One column: a flexible share of the width, or a fixed one (the numbers,
/// right-aligned).
class _Column {
  const _Column(this.key, this.label, {this.flex, this.width});

  final SavedSortKey key;
  final String label;
  final int? flex;
  final double? width;

  bool get numeric => width != null;
}

/// The runs of one [kind] as dense rows: a header that sorts, a check box
/// per row, and each row opening its run.
class SavedTable extends ConsumerWidget {
  const SavedTable({super.key, required this.kind, required this.entries});

  final SavedKind kind;
  final List<SavedEntry> entries;

  /// The columns that fit [width], the least telling dropped first, so the
  /// name and machine keep ~200 px between them.
  List<_Column> _columns(double width) {
    final perf = kind == SavedKind.perf;
    return [
      const _Column(SavedSortKey.name, 'Name', flex: 3),
      const _Column(SavedSortKey.machine, 'Machine', flex: 2),
      if (width >= 740) const _Column(SavedSortKey.model, 'Model', flex: 2),
      _Column(SavedSortKey.concurrency, perf ? 'Conc.' : 'Batch', width: 76),
      _Column(SavedSortKey.throughput, perf ? 'tok/s' : 'tok/s agg', width: 96),
      if (width >= 600) const _Column(SavedSortKey.ttft, 'TTFT p50', width: 96),
      if (width >= 900)
        const _Column(SavedSortKey.duration, 'Duration', width: 92),
      if (width >= 600) const _Column(SavedSortKey.date, 'Saved', width: 96),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final browse = ref.watch(savedBrowserProvider);
    final browser = ref.read(savedBrowserProvider.notifier);
    final ids = [for (final e in entries) e.id];
    final allPicked = ids.every(browse.selected.contains);
    final somePicked = ids.any(browse.selected.contains);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columns(constraints.maxWidth);
        return AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header.
              Container(
                height: _rowHeight,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  border: Border(bottom: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    _CheckCell(
                      value: allPicked,
                      partial: somePicked && !allPicked,
                      onTap: () => browser.toggleAll(ids),
                    ),
                    for (final col in columns)
                      _sized(
                        col,
                        _HeaderCell(
                          column: col,
                          sorted: browse.sortKey == col.key,
                          descending: browse.descending,
                          onTap: () => browser.sortBy(col.key),
                        ),
                      ),
                    const SizedBox(width: _actionWidth),
                  ],
                ),
              ),
              for (final (i, e) in entries.indexed)
                _Row(
                  entry: e,
                  columns: columns,
                  selected: browse.selected.contains(e.id),
                  last: i == entries.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }
}

Widget _sized(_Column col, Widget child) => col.flex != null
    ? Expanded(flex: col.flex!, child: child)
    : SizedBox(width: col.width, child: child);

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.sorted,
    required this.descending,
    required this.onTap,
  });

  final _Column column;
  final bool sorted;
  final bool descending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) {
        final color = sorted || hovered ? c.textPrimary : c.textMuted;
        // Only on the sorted column, on the side away from the text's
        // alignment edge so the labels stay lined up with their values.
        final arrow = [
          if (sorted)
            Icon(
              descending ? AppIcons.sortDescending : AppIcons.sortAscending,
              size: 11,
              color: color,
            ),
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: column.numeric
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            spacing: 3,
            children: [
              if (column.numeric) ...arrow,
              Flexible(
                child: Text(
                  column.label,
                  style: context.text.columnHeader.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!column.numeric) ...arrow,
            ],
          ),
        );
      },
    );
  }
}

class _CheckCell extends StatelessWidget {
  const _CheckCell({
    required this.value,
    required this.onTap,
    this.partial = false,
  });

  final bool value;
  final bool partial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) => SizedBox(
        width: _checkWidth,
        height: _rowHeight,
        child: Center(
          child: partial
              ? Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: c.accent),
                  ),
                  child: Center(
                    child: Container(width: 7, height: 1.5, color: c.accent),
                  ),
                )
              : AppCheckbox(value: value, hovered: hovered),
        ),
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({
    required this.entry,
    required this.columns,
    required this.selected,
    required this.last,
  });

  final SavedEntry entry;
  final List<_Column> columns;
  final bool selected;
  final bool last;

  Widget _cell(BuildContext context, _Column col) {
    final c = context.colors;
    final e = entry;
    Widget text(String s, TextStyle style) => Text(
      s,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: col.numeric ? TextAlign.right : TextAlign.left,
    );
    final mono = context.text.monoSmall;
    final faint = mono.copyWith(color: c.textFaint);
    final child = switch (col.key) {
      SavedSortKey.name => Row(
        children: [
          if (e is PerfEntry) ...[
            Icon(AppIcons.perf, size: 11, color: c.textFaint),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: text(
              e.name,
              context.text.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      SavedSortKey.machine => text(e.machine, mono),
      SavedSortKey.model =>
        e.model.isEmpty ? text('—', faint) : text(modelLabel(e.model), mono),
      SavedSortKey.concurrency => text('${e.concurrency}', mono),
      SavedSortKey.throughput => text(
        e.throughput.toStringAsFixed(1),
        mono.copyWith(color: c.statusRunning, fontWeight: FontWeight.w600),
      ),
      SavedSortKey.ttft => switch (e.ttftMs) {
        final ms? => text('${ms.round()} ms', mono),
        null => text('—', faint),
      },
      SavedSortKey.duration => text(
        e.seconds >= 10
            ? '${e.seconds.toStringAsFixed(0)} s'
            : '${e.seconds.toStringAsFixed(1)} s',
        mono,
      ),
      SavedSortKey.date => text(
        formatWhen(e.createdAt),
        context.text.smallMuted,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Align(
        alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final browser = ref.read(savedBrowserProvider.notifier);
    return HoverRegion(
      onTap: () => tapSavedEntry(context, ref, entry),
      builder: (context, hovered) => Container(
        height: _rowHeight,
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: hovered ? 0.12 : 0.08)
              : (hovered ? c.surfaceHover : null),
          border: last
              ? null
              : Border(bottom: BorderSide(color: c.borderMuted)),
        ),
        child: Row(
          children: [
            _CheckCell(value: selected, onTap: () => browser.toggle(entry.id)),
            for (final col in columns) _sized(col, _cell(context, col)),
            SizedBox(
              width: _actionWidth,
              child: hovered
                  ? AppIconButton(
                      icon: AppIcons.delete,
                      size: 13,
                      color: c.textMuted,
                      hoverColor: c.statusFailed,
                      padding: const EdgeInsets.all(5),
                      onPressed: () => browser.delete([entry]),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
