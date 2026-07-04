// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_benchmark_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(savedBenchmarkRepository)
final savedBenchmarkRepositoryProvider = SavedBenchmarkRepositoryProvider._();

final class SavedBenchmarkRepositoryProvider
    extends
        $FunctionalProvider<
          SavedBenchmarkRepository,
          SavedBenchmarkRepository,
          SavedBenchmarkRepository
        >
    with $Provider<SavedBenchmarkRepository> {
  SavedBenchmarkRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedBenchmarkRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedBenchmarkRepositoryHash();

  @$internal
  @override
  $ProviderElement<SavedBenchmarkRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedBenchmarkRepository create(Ref ref) {
    return savedBenchmarkRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedBenchmarkRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedBenchmarkRepository>(value),
    );
  }
}

String _$savedBenchmarkRepositoryHash() =>
    r'8f583cdb6c1044b684cde5e8fdcd0105adad7ae9';
