// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jobs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(jobsStream)
final jobsStreamProvider = JobsStreamProvider._();

final class JobsStreamProvider
    extends
        $FunctionalProvider<AsyncValue<List<Job>>, List<Job>, Stream<List<Job>>>
    with $FutureModifier<List<Job>>, $StreamProvider<List<Job>> {
  JobsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Job>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Job>> create(Ref ref) {
    return jobsStream(ref);
  }
}

String _$jobsStreamHash() => r'4afffb270d2560d556428a4f143b90e64ca226d8';

@ProviderFor(JobFilter)
final jobFilterProvider = JobFilterProvider._();

final class JobFilterProvider
    extends $NotifierProvider<JobFilter, JobFilterKind> {
  JobFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobFilterHash();

  @$internal
  @override
  JobFilter create() => JobFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JobFilterKind value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JobFilterKind>(value),
    );
  }
}

String _$jobFilterHash() => r'badd23d58ed5c080f71a4e98e1d861b254049bdf';

abstract class _$JobFilter extends $Notifier<JobFilterKind> {
  JobFilterKind build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<JobFilterKind, JobFilterKind>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JobFilterKind, JobFilterKind>,
              JobFilterKind,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Filtered, machine-resolved job rows for the dashboard.

@ProviderFor(jobList)
final jobListProvider = JobListProvider._();

/// Filtered, machine-resolved job rows for the dashboard.

final class JobListProvider
    extends
        $FunctionalProvider<
          List<JobListEntry>,
          List<JobListEntry>,
          List<JobListEntry>
        >
    with $Provider<List<JobListEntry>> {
  /// Filtered, machine-resolved job rows for the dashboard.
  JobListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobListHash();

  @$internal
  @override
  $ProviderElement<List<JobListEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<JobListEntry> create(Ref ref) {
    return jobList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<JobListEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<JobListEntry>>(value),
    );
  }
}

String _$jobListHash() => r'6fc9e5a75a88ddd9c082180c78c6a3bd56bb6c65';

/// Running / total, for the dashboard header and sidebar badge.

@ProviderFor(jobCounts)
final jobCountsProvider = JobCountsProvider._();

/// Running / total, for the dashboard header and sidebar badge.

final class JobCountsProvider
    extends
        $FunctionalProvider<
          ({int running, int total}),
          ({int running, int total}),
          ({int running, int total})
        >
    with $Provider<({int running, int total})> {
  /// Running / total, for the dashboard header and sidebar badge.
  JobCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobCountsHash();

  @$internal
  @override
  $ProviderElement<({int running, int total})> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ({int running, int total}) create(Ref ref) {
    return jobCounts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int running, int total}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int running, int total})>(value),
    );
  }
}

String _$jobCountsHash() => r'371f74dbcb6b5f18a5d8725ebb0dfc26b16cd282';
