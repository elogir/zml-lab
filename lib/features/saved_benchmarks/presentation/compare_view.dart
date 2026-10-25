import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/perf_report.dart';
import '../../perf/presentation/perf_charts.dart';
import '../domain/saved_entry.dart';

/// Opens [entries] (one kind, a few of them) side by side: their setup,
/// their results against a baseline, and — perf runs — their throughput.
/// Oldest first, so the baseline starts as the earliest run and the changes
/// read as what came after it.
void showCompare(BuildContext context, List<SavedEntry> entries) {
  final ordered = entries.sortedBy((e) => e.createdAt);
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _CompareView(entries: ordered),
      transitionsBuilder: (context, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

/// The runs' colors, in order — a categorical palette checked for color
/// blindness, stepped for each theme. Green and red come last: they're
/// also the deltas' better / worse.
const _seriesLight = [
  Color(0xFF2A78D6),
  Color(0xFFEB6834),
  Color(0xFF1BAF7A),
  Color(0xFFEDA100),
  Color(0xFFE87BA4),
  Color(0xFF6250D6),
];
const _seriesDark = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
  Color(0xFF9085E9),
];

/// How many runs Compare takes at once.
const maxCompared = 6;

enum _Better { higher, lower }

/// A setup row: the same for every run, or not.
class _Fact {
  const _Fact(this.label, this.text);

  final String label;
  final String Function(SavedEntry) text;
}

/// A result row: a number per run, and — when there's a [better] direction
/// — each run's change against the baseline.
class _Measure {
  const _Measure(
    this.label,
    this.value, {
    this.unit = '',
    this.better,
    this.digits = 0,
  });

  final String label;
  final double? Function(SavedEntry) value;
  final String unit;
  final _Better? better;
  final int digits;

  String format(double v) {
    final n = v.toStringAsFixed(digits);
    return unit.isEmpty ? n : '$n $unit';
  }
}

String _yesNo(bool b) => b ? 'yes' : 'no';

List<_Fact> _facts(SavedKind kind) => switch (kind) {
  SavedKind.perf => [
    _Fact('Machine', (e) => e.machine),
    _Fact('Endpoint', (e) => (e as PerfEntry).report.endpoint),
    _Fact('Model', (e) => e.model.isEmpty ? '—' : e.model),
    _Fact('Hardware', (e) => (e as PerfEntry).hardware ?? '—'),
    _Fact('Concurrency', (e) => '${e.concurrency}'),
    _Fact(
      'Duration',
      (e) => '${(e as PerfEntry).report.params.durationSeconds} s',
    ),
    _Fact('Prompts', (e) => (e as PerfEntry).report.params.sequenceType),
    _Fact(
      'Turns',
      (e) =>
          (e as PerfEntry).report.params.mode == 'first' ? 'first only' : 'all',
    ),
    _Fact(
      'Max tokens',
      (e) =>
          '${(e as PerfEntry).report.params.maxCompletionTokens ?? 'no cap'}',
    ),
    _Fact(
      'Ignore EOS',
      (e) => _yesNo((e as PerfEntry).report.params.ignoreEos),
    ),
    _Fact('Warm-up', (e) => _yesNo((e as PerfEntry).report.params.warmup)),
    _Fact(
      'Run',
      (e) => (e as PerfEntry).report.cancelled ? 'stopped early' : 'complete',
    ),
  ],
  SavedKind.chat => [
    _Fact('Machine', (e) => e.machine),
    _Fact('Endpoint', (e) => (e as ChatEntry).benchmark.endpoint),
    _Fact('Model', (e) => e.model.isEmpty ? '—' : e.model),
    _Fact('Batch', (e) => '${e.concurrency}'),
    _Fact(
      'Max tokens',
      (e) => '${(e as ChatEntry).benchmark.maxTokens ?? 'unlimited'}',
    ),
    _Fact(
      'Temperature',
      (e) => '${(e as ChatEntry).benchmark.temperature ?? 'server default'}',
    ),
    _Fact('Ignore EOS', (e) => _yesNo((e as ChatEntry).benchmark.ignoreEos)),
    _Fact('Prompt', (e) => (e as ChatEntry).benchmark.prompt),
  ],
};

List<_Measure> _measures(SavedKind kind) {
  switch (kind) {
    case SavedKind.perf:
      double? p(SavedEntry e, String label, double Function(PerfStatRow) pick) {
        final row = (e as PerfEntry).report.stat(label);
        return row == null ? null : pick(row);
      }
      _Measure stat(
        String name,
        String label,
        String which,
        double Function(PerfStatRow) pick, {
        int digits = 0,
      }) => _Measure(
        '$name $which',
        (e) => p(e, label, pick),
        unit: 'ms',
        better: _Better.lower,
        digits: digits,
      );
      PerfEntry r(SavedEntry e) => e as PerfEntry;
      return [
        _Measure(
          'Throughput',
          (e) => e.throughput,
          unit: 'tok/s',
          better: _Better.higher,
          digits: 1,
        ),
        _Measure(
          'Requests/s',
          (e) => r(e).report.requestsPerSecond,
          better: _Better.higher,
          digits: 2,
        ),
        _Measure('Requests', (e) => r(e).report.totalRequests.toDouble()),
        _Measure('Errors', (e) => r(e).report.errorCount.toDouble()),
        stat('TTFT', 'Time to first token', 'p50', (s) => s.p50),
        stat('TTFT', 'Time to first token', 'p90', (s) => s.p90),
        stat('TTFT', 'Time to first token', 'p99', (s) => s.p99),
        stat('ITL', 'Inter-token latency', 'p50', (s) => s.p50, digits: 1),
        stat('ITL', 'Inter-token latency', 'p90', (s) => s.p90, digits: 1),
        stat('ITL', 'Inter-token latency', 'p99', (s) => s.p99, digits: 1),
        stat('Latency', 'Request latency', 'p50', (s) => s.p50),
        stat('Latency', 'Request latency', 'p99', (s) => s.p99),
        _Measure(
          'Output length avg',
          (e) => p(e, 'Output sequence length', (s) => s.avg),
          unit: 'tok',
        ),
        _Measure(
          'Energy',
          (e) => r(e).report.joulesPerToken,
          unit: 'J/tok',
          better: _Better.lower,
          digits: 3,
        ),
      ];
    case SavedKind.chat:
      ChatEntry b(SavedEntry e) => e as ChatEntry;
      return [
        _Measure(
          'Aggregate',
          (e) => e.throughput,
          unit: 'tok/s',
          better: _Better.higher,
          digits: 1,
        ),
        _Measure(
          'Per request',
          (e) => b(e).benchmark.averageTokensPerSecond,
          unit: 'tok/s',
          better: _Better.higher,
          digits: 1,
        ),
        _Measure(
          'TTFT median',
          (e) => e.ttftMs,
          unit: 'ms',
          better: _Better.lower,
        ),
        _Measure(
          'Elapsed',
          (e) => e.seconds,
          unit: 's',
          better: _Better.lower,
          digits: 1,
        ),
        _Measure('Completed', (e) => b(e).benchmark.completed.toDouble()),
      ];
  }
}

/// [v]'s change from [base] in percent, or null when there's no base.
double? _change(double? v, double? base) =>
    v == null || base == null || base == 0 ? null : (v - base) / base * 100;

/// The setup rows [entries] have something for (no row of only dashes).
List<_Fact> _shownFacts(List<SavedEntry> entries) => [
  for (final f in _facts(entries.first.kind))
    if (entries.any((e) => f.text(e) != '—')) f,
];

/// The result rows [entries] have a number for.
List<_Measure> _shownMeasures(List<SavedEntry> entries) => [
  for (final m in _measures(entries.first.kind))
    if (entries.any((e) => m.value(e) != null)) m,
];

/// The comparison as aligned plain text, for Copy.
String compareText(List<SavedEntry> entries, int baseline) {
  final rows = <List<String>>[
    ['', for (final e in entries) e.name],
    for (final f in _shownFacts(entries))
      [f.label, for (final e in entries) f.text(e)],
    for (final m in _shownMeasures(entries))
      [
        m.label,
        for (final (i, e) in entries.indexed)
          switch (m.value(e)) {
            null => '—',
            final v => switch (i == baseline || m.better == null
                ? null
                : _change(v, m.value(entries[baseline]))) {
              null => m.format(v),
              final d => '${m.format(v)} (${_signed(d)})',
            },
          },
      ],
  ];
  final widths = [
    for (var col = 0; col < rows.first.length; col++)
      rows.map((r) => r[col].length).fold(0, math.max),
  ];
  return [
    for (final r in rows)
      [
        for (final (col, cell) in r.indexed) cell.padRight(widths[col]),
      ].join('  ').trimRight(),
  ].join('\n');
}

String _signed(double pct) {
  final s = pct.abs().toStringAsFixed(1);
  if (s == '0.0') return '±0%';
  return '${pct > 0 ? '+' : '−'}$s%';
}

class _CompareView extends StatefulWidget {
  const _CompareView({required this.entries});

  final List<SavedEntry> entries;

  @override
  State<_CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<_CompareView> {
  /// The run the others are measured against.
  int _baseline = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entries = widget.entries;
    final kind = entries.first.kind;
    final palette = c.brightness == Brightness.dark
        ? _seriesDark
        : _seriesLight;
    final colors = [
      for (var i = 0; i < entries.length; i++) palette[i % palette.length],
    ];
    final size = MediaQuery.sizeOf(context);
    final width = (size.width * 0.8).clamp(560.0, 1280.0);
    final height = (size.height * 0.85).clamp(420.0, 980.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: height),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppPanel(
            color: c.surface,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.compare, size: 15, color: c.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compare ${entries.length} '
                            '${kind == SavedKind.perf ? 'perf reports' : 'chat benchmarks'}',
                            style: context.text.bodyStrong,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Changes are against the baseline — click a '
                            'run\'s name to make it the baseline.',
                            style: context.text.smallMuted,
                          ),
                        ],
                      ),
                    ),
                    CopyButton(
                      text: compareText(entries, _baseline),
                      label: 'Copy table',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _CompareBody(
                    entries: entries,
                    colors: colors,
                    baseline: _baseline,
                    onBaseline: (i) => setState(() => _baseline = i),
                    chart: kind == SavedKind.perf
                        ? PerfChartCard(
                            title: 'Throughput',
                            unit: 'tok/s',
                            height: 220,
                            child: PerfCompareChart(
                              runs: [
                                for (final (i, e) in entries.indexed)
                                  (
                                    name: e.name,
                                    color: colors[i],
                                    series: (e as PerfEntry).report.series,
                                  ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The chart (perf runs) and the table under it, scrolling together; the
/// runs' names stay pinned at the top so every column keeps its name.
class _CompareBody extends StatelessWidget {
  const _CompareBody({
    required this.entries,
    required this.colors,
    required this.baseline,
    required this.onBaseline,
    this.chart,
  });

  final List<SavedEntry> entries;
  final List<Color> colors;
  final int baseline;
  final ValueChanged<int> onBaseline;
  final Widget? chart;

  static const _labelWidth = 150.0;
  static const _minColumn = 150.0;
  static const _headerHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final column = math.max(
          _minColumn,
          (constraints.maxWidth - _labelWidth) / entries.length,
        );
        final total = _labelWidth + column * entries.length;

        Widget row(Widget label, List<Widget> cells, {bool header = false}) =>
            Container(
              constraints: BoxConstraints(minHeight: header ? 52 : 30),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.borderMuted)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: _labelWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: label,
                      ),
                    ),
                    for (final (i, cell) in cells.indexed)
                      Container(
                        width: column,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        alignment: Alignment.centerLeft,
                        color: i == baseline ? c.surfaceMuted : null,
                        child: cell,
                      ),
                  ],
                ),
              ),
            );

        Widget factRow(_Fact f) {
          final texts = [for (final e in entries) f.text(e)];
          // What differs between the runs stands out; what they share
          // recedes.
          final color = texts.toSet().length > 1 ? c.textPrimary : c.textMuted;
          return row(
            Text(f.label, style: context.text.small.copyWith(color: color)),
            [
              for (final t in texts)
                Text(
                  t,
                  style: context.text.monoSmall.copyWith(color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          );
        }

        Widget section(String title) => Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: SectionLabel(title),
        );

        final header = SizedBox(
          height: _headerHeight,
          child: row(const SizedBox(), header: true, [
            for (final (i, e) in entries.indexed)
              _RunHeader(
                entry: e,
                color: colors[i],
                baseline: i == baseline,
                onTap: () => onBaseline(i),
              ),
          ]),
        );
        Widget body = CustomScrollView(
          slivers: [
            if (chart case final chart?)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: chart,
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeader(
                height: _headerHeight,
                color: c.surface,
                child: header,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  section('SETUP'),
                  for (final f in _shownFacts(entries)) factRow(f),
                  section('RESULTS'),
                  for (final m in _shownMeasures(entries))
                    row(Text(m.label, style: context.text.small), [
                      for (final (i, e) in entries.indexed)
                        _MeasureCell(
                          measure: m,
                          value: m.value(e),
                          change: i == baseline || m.better == null
                              ? null
                              : _change(m.value(e), m.value(entries[baseline])),
                        ),
                    ]),
                ],
              ),
            ),
          ],
        );
        // Too many runs for the width: the whole view scrolls sideways
        // too, the header along with its columns.
        if (total > constraints.maxWidth) {
          body = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: total, child: body),
          );
        }
        return body;
      },
    );
  }
}

/// The runs' names, kept at the top while the table scrolls under them.
class _PinnedHeader extends SliverPersistentHeaderDelegate {
  _PinnedHeader({
    required this.height,
    required this.color,
    required this.child,
  });

  final double height;

  /// Opaque, so the rows scrolling under it don't show through.
  final Color color;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(color: color, child: child);

  @override
  bool shouldRebuild(_PinnedHeader old) => true;
}

/// A run's column head: its color (the chart's line), name and where it
/// ran; a click makes it the baseline.
class _RunHeader extends StatelessWidget {
  const _RunHeader({
    required this.entry,
    required this.color,
    required this.baseline,
    required this.onTap,
  });

  final SavedEntry entry;
  final Color color;
  final bool baseline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  entry.name,
                  style: context.text.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            baseline
                ? 'baseline'
                : (hovered ? 'make baseline' : formatWhen(entry.createdAt)),
            style: context.text.smallMuted.copyWith(
              color: baseline || hovered ? c.accent : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasureCell extends StatelessWidget {
  const _MeasureCell({
    required this.measure,
    required this.value,
    required this.change,
  });

  final _Measure measure;
  final double? value;

  /// Percent change against the baseline, when it's measured.
  final double? change;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = value;
    if (v == null) {
      return Text(
        '—',
        style: context.text.monoSmall.copyWith(color: c.textFaint),
      );
    }
    final d = change;
    final Color? tint;
    if (d == null || d.abs() < 0.05) {
      tint = null;
    } else {
      final better = (d > 0) == (measure.better == _Better.higher);
      tint = better ? c.statusRunning : c.statusFailed;
    }
    return Row(
      children: [
        Text(measure.format(v), style: context.text.mono),
        if (d != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            _signed(d),
            style: context.text.monoSmall.copyWith(color: tint ?? c.textFaint),
          ),
        ],
      ],
    );
  }
}
