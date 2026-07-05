import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/saved_benchmark.dart';
import '../../../repositories/saved_benchmark_repository.dart';
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

  bool _matches(SavedBenchmark b, String q) =>
      b.name.toLowerCase().contains(q) ||
      b.endpoint.toLowerCase().contains(q) ||
      b.prompt.toLowerCase().contains(q);

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(savedBenchmarksStreamProvider).value ?? const [];
    final q = _query.trim().toLowerCase();
    final benchmarks = q.isEmpty
        ? all
        : all.where((b) => _matches(b, q)).toList();

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(
            title: 'Saved benchmarks',
            subtitle:
                'Named snapshots of past runs. Open one to review its responses.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSearchField(
            hintText: 'Search benchmarks',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: benchmarks.isEmpty
                ? _EmptyState(searching: q.isNotEmpty)
                : SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = AppSpacing.lg;
                        final width = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final b in benchmarks)
                              SizedBox(
                                width: width,
                                child: _BenchmarkCard(benchmark: b),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
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
              Text('tok/s', style: context.text.monoSmall),
              const Spacer(),
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
