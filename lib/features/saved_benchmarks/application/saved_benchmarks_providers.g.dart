// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_benchmarks_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(savedBenchmarksStream)
final savedBenchmarksStreamProvider = SavedBenchmarksStreamProvider._();

final class SavedBenchmarksStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedBenchmark>>,
          List<SavedBenchmark>,
          Stream<List<SavedBenchmark>>
        >
    with
        $FutureModifier<List<SavedBenchmark>>,
        $StreamProvider<List<SavedBenchmark>> {
  SavedBenchmarksStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedBenchmarksStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedBenchmarksStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<SavedBenchmark>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SavedBenchmark>> create(Ref ref) {
    return savedBenchmarksStream(ref);
  }
}

String _$savedBenchmarksStreamHash() =>
    r'b666bb2c5498473c0c7b41bd20f8c703c33356b4';
