// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_executor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(jobExecutor)
final jobExecutorProvider = JobExecutorProvider._();

final class JobExecutorProvider
    extends $FunctionalProvider<JobExecutor, JobExecutor, JobExecutor>
    with $Provider<JobExecutor> {
  JobExecutorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobExecutorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobExecutorHash();

  @$internal
  @override
  $ProviderElement<JobExecutor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JobExecutor create(Ref ref) {
    return jobExecutor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JobExecutor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JobExecutor>(value),
    );
  }
}

String _$jobExecutorHash() => r'5262dbff03ef77289afa63052fe3aec4fd7a69ab';
