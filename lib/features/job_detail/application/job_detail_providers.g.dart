// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_detail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live view of a single job for the detail screen header.

@ProviderFor(jobStream)
final jobStreamProvider = JobStreamFamily._();

/// Live view of a single job for the detail screen header.

final class JobStreamProvider
    extends $FunctionalProvider<AsyncValue<Job?>, Job?, Stream<Job?>>
    with $FutureModifier<Job?>, $StreamProvider<Job?> {
  /// Live view of a single job for the detail screen header.
  JobStreamProvider._({
    required JobStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'jobStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$jobStreamHash();

  @override
  String toString() {
    return r'jobStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Job?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Job?> create(Ref ref) {
    final argument = this.argument as String;
    return jobStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JobStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$jobStreamHash() => r'6ae93e0acac8af38688308e5d38ffd539108bbc3';

/// Live view of a single job for the detail screen header.

final class JobStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Job?>, String> {
  JobStreamFamily._()
    : super(
        retry: null,
        name: r'jobStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live view of a single job for the detail screen header.

  JobStreamProvider call(String id) =>
      JobStreamProvider._(argument: id, from: this);

  @override
  String toString() => r'jobStreamProvider';
}
