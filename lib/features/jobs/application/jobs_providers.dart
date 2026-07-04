import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/job.dart';
import '../../../models/machine.dart';
import '../../../repositories/job_repository.dart';
import '../../machines/application/machines_providers.dart';

part 'jobs_providers.g.dart';

/// The dashboard's filter chips.
enum JobFilterKind {
  all,
  running,
  stopped;

  String get label => switch (this) {
    JobFilterKind.all => 'All',
    JobFilterKind.running => 'Running',
    JobFilterKind.stopped => 'Stopped',
  };
}

/// A job paired with its (resolved) machine, for list rendering.
class JobListEntry {
  const JobListEntry({required this.job, required this.machine});

  final Job job;
  final Machine? machine;
}

@riverpod
Stream<List<Job>> jobsStream(Ref ref) =>
    ref.watch(jobRepositoryProvider).watchJobs();

@riverpod
class JobFilter extends _$JobFilter {
  @override
  JobFilterKind build() => JobFilterKind.all;

  void select(JobFilterKind kind) => state = kind;
}

/// Filtered, machine-resolved job rows for the dashboard.
@riverpod
List<JobListEntry> jobList(Ref ref) {
  final jobs = ref.watch(jobsStreamProvider).value ?? const [];
  final machines = ref.watch(machineMapProvider);
  final filter = ref.watch(jobFilterProvider);

  final filtered = jobs.where(
    (j) => switch (filter) {
      JobFilterKind.all => true,
      JobFilterKind.running => j.status.isActive,
      JobFilterKind.stopped => j.isStopped,
    },
  );

  return [
    for (final j in filtered)
      JobListEntry(job: j, machine: machines[j.machineId]),
  ];
}

/// Running / total, for the dashboard header and sidebar badge.
@riverpod
({int running, int total}) jobCounts(Ref ref) {
  final jobs = ref.watch(jobsStreamProvider).value ?? const [];
  return (
    running: jobs.where((j) => j.status.isRunning).length,
    total: jobs.length,
  );
}
