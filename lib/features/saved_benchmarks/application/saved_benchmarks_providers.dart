import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/perf_report.dart';
import '../../../models/saved_benchmark.dart';
import '../../../repositories/perf_report_repository.dart';
import '../../../repositories/saved_benchmark_repository.dart';

part 'saved_benchmarks_providers.g.dart';

@riverpod
Stream<List<SavedBenchmark>> savedBenchmarksStream(Ref ref) =>
    ref.watch(savedBenchmarkRepositoryProvider).watchBenchmarks();

@riverpod
Stream<List<PerfReport>> perfReportsStream(Ref ref) =>
    ref.watch(perfReportRepositoryProvider).watchReports();
