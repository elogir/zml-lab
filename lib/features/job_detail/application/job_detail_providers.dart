import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/job.dart';
import '../../../repositories/job_repository.dart';

part 'job_detail_providers.g.dart';

/// Live view of a single job for the detail screen header.
@riverpod
Stream<Job?> jobStream(Ref ref, String id) =>
    ref.watch(jobRepositoryProvider).watchJob(id);
