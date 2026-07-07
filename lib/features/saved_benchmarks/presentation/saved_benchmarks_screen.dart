import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/util/search.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/perf_report.dart';
import '../../../models/saved_benchmark.dart';
import '../../../repositories/perf_report_repository.dart';
import '../../../repositories/saved_benchmark_repository.dart';
import '../../perf/presentation/perf_report_detail.dart';
import '../application/saved_benchmarks_providers.dart';
import 'saved_benchmark_detail.dart';

class SavedBenchmarksScreen extends ConsumerStatefulWidget {
  const SavedBenchmarksScreen({super.key});

  @override
  ConsumerState<SavedBenchmarksScreen> createState() =>
      _SavedBenchmarksScreenState();
}

class _SavedBenchmarksScreenState extends ConsumerState<SavedBenchmarksScreen> {
  String _query = '';

  bool _matches(SavedBenchmark b, String q) => matchesSearch(q, [
    b.name,
    b.endpoint,
    b.machineName,
    b.command,
    b.prompt,
  ]);

  bool _matchesReport(PerfReport r, String q) => matchesSearch(q, [
    r.name,
    r.endpoint,
    r.machineName,
    r.serverLabel,
    r.params.model,
    r.benchCommand,
    r.jobCommand,
  ]);

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(savedBenchmarksStreamProvider).value ?? const [];
    final allReports = ref.watch(perfReportsStreamProvider).value ?? const [];
    final q = _query.trim();
    final benchmarks = q.isEmpty
        ? all
        : all.where((b) => _matches(b, q)).toList();
    final reports = q.isEmpty
        ? allReports
        : allReports.where((r) => _matchesReport(r, q)).toList();
    // Group labels only earn their place when both kinds are present.
    final labelled = benchmarks.isNotEmpty && reports.isNotEmpty;

    Widget grid(List<Widget> cards) => LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.lg;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );

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
          AppSearchField(
            hintText: 'Search benchmarks',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: benchmarks.isEmpty && reports.isEmpty
                ? _EmptyState(searching: q.isNotEmpty)
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (reports.isNotEmpty) ...[
                          if (labelled) ...[
                            const SectionLabel('PERF REPORTS'),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          grid([
                            for (final r in reports)
                              _PerfReportCard(report: r),
                          ]),
                        ],
                        if (labelled) const SizedBox(height: AppSpacing.xl),
                        if (benchmarks.isNotEmpty) ...[
                          if (labelled) ...[
                            const SectionLabel('CHAT BENCHMARKS'),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          grid([
                            for (final b in benchmarks)
                              _BenchmarkCard(benchmark: b),
                          ]),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PerfReportCard extends ConsumerWidget {
  const _PerfReportCard({required this.report});

  final PerfReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final r = report;
    final ttft = r.stats
        .where((s) => s.label == 'Time to first token')
        .firstOrNull;

    return AppCard(
      onTap: () => showPerfReportDetail(context, r),
      onDelete: () => ref.read(perfReportRepositoryProvider).delete(r.id),
      topRight: Text(formatAgo(r.createdAt), style: context.text.smallMuted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 44),
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
          Row(
            children: [
              Icon(AppIcons.machines, size: 12, color: c.textFaint),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  r.endpoint,
                  style: context.text.monoSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(r.serverLabel, style: context.text.smallMuted),
              const SizedBox(width: AppSpacing.md),
              Text(
                'c ${r.params.concurrency}',
                style: context.text.smallMuted,
              ),
            ],
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
              const Spacer(),
              _Metric(
                label: 'req/s',
                value: r.requestsPerSecond.toStringAsFixed(2),
              ),
              const SizedBox(width: AppSpacing.lg),
              if (ttft != null) ...[
                _Metric(
                  label: 'ttft p50',
                  value: '${ttft.p50.round()}ms',
                ),
                const SizedBox(width: AppSpacing.lg),
              ],
              _Metric(
                label: 'dur',
                value: '${r.totalSeconds.toStringAsFixed(0)}s',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenchmarkCard extends ConsumerWidget {
  const _BenchmarkCard({required this.benchmark});

  final SavedBenchmark benchmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final b = benchmark;

    return AppCard(
      onTap: () => showSavedBenchmarkDetail(context, b),
      onDelete: () =>
          ref.read(savedBenchmarkRepositoryProvider).delete(b.id),
      topRight: Text(formatAgo(b.createdAt), style: context.text.smallMuted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave room on the right for the top-right timestamp, which the
          // hover trash icon replaces.
          Padding(
            padding: const EdgeInsets.only(right: 44),
            child: Text(
              b.name,
              style: context.text.body.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(AppIcons.machines, size: 12, color: c.textFaint),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${b.machineLabel} ${b.portLabel}',
                  style: context.text.monoSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('batch ${b.batchSize}', style: context.text.smallMuted),
            ],
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
              const Spacer(),
              _Metric(
                label: 'avg',
                value: '${b.averageTokensPerSecond.toStringAsFixed(1)} t/s',
              ),
              const SizedBox(width: AppSpacing.lg),
              _Metric(label: 'ttft', value: '${b.medianTtftMs}ms'),
              const SizedBox(width: AppSpacing.lg),
              _Metric(
                label: 'elapsed',
                value: '${(b.elapsedMs / 1000).toStringAsFixed(1)}s',
              ),
            ],
          ),
        ],
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
      children: [
        Text(label, style: context.text.monoSmall.copyWith(color: c.textFaint)),
        const SizedBox(width: 5),
        Text(value, style: context.text.monoSmall),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.searching = false});

  final bool searching;

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
            searching ? 'No matching benchmarks' : 'No saved benchmarks',
            style: context.text.bodySecondary,
          ),
          const SizedBox(height: 4),
          Text(
            searching
                ? 'Try a different search.'
                : 'Run a benchmark on a job, then Save it to keep it here.',
            style: context.text.smallMuted,
          ),
        ],
      ),
    );
  }
}
