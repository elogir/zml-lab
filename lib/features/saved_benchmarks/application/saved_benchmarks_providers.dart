import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/saved_benchmark.dart';
import '../../../repositories/saved_benchmark_repository.dart';

part 'saved_benchmarks_providers.g.dart';

@riverpod
Stream<List<SavedBenchmark>> savedBenchmarksStream(Ref ref) =>
    ref.watch(savedBenchmarkRepositoryProvider).watchBenchmarks();
