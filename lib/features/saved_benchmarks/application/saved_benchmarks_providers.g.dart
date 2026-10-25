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

@ProviderFor(perfReportsStream)
final perfReportsStreamProvider = PerfReportsStreamProvider._();

final class PerfReportsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PerfReport>>,
          List<PerfReport>,
          Stream<List<PerfReport>>
        >
    with $FutureModifier<List<PerfReport>>, $StreamProvider<List<PerfReport>> {
  PerfReportsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'perfReportsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$perfReportsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<PerfReport>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PerfReport>> create(Ref ref) {
    return perfReportsStream(ref);
  }
}

String _$perfReportsStreamHash() => r'1333aae8bd43c4eb8b106936065c9857685ba744';

/// Every saved run, perf reports first, each kind newest first.

@ProviderFor(savedEntries)
final savedEntriesProvider = SavedEntriesProvider._();

/// Every saved run, perf reports first, each kind newest first.

final class SavedEntriesProvider
    extends
        $FunctionalProvider<
          List<SavedEntry>,
          List<SavedEntry>,
          List<SavedEntry>
        >
    with $Provider<List<SavedEntry>> {
  /// Every saved run, perf reports first, each kind newest first.
  SavedEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedEntriesHash();

  @$internal
  @override
  $ProviderElement<List<SavedEntry>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<SavedEntry> create(Ref ref) {
    return savedEntries(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SavedEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SavedEntry>>(value),
    );
  }
}

String _$savedEntriesHash() => r'a240a6180ff71fd27cc72333f3da7d5bcdf03aff';

/// The Saved benchmarks tab's filters, sort, view and selection — kept
/// while you're on other tabs.

@ProviderFor(SavedBrowser)
final savedBrowserProvider = SavedBrowserProvider._();

/// The Saved benchmarks tab's filters, sort, view and selection — kept
/// while you're on other tabs.
final class SavedBrowserProvider
    extends $NotifierProvider<SavedBrowser, SavedBrowse> {
  /// The Saved benchmarks tab's filters, sort, view and selection — kept
  /// while you're on other tabs.
  SavedBrowserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedBrowserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedBrowserHash();

  @$internal
  @override
  SavedBrowser create() => SavedBrowser();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedBrowse value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedBrowse>(value),
    );
  }
}

String _$savedBrowserHash() => r'ebe53807d7a4c5ebf3dccc50af030304c7f44aea';

/// The Saved benchmarks tab's filters, sort, view and selection — kept
/// while you're on other tabs.

abstract class _$SavedBrowser extends $Notifier<SavedBrowse> {
  SavedBrowse build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SavedBrowse, SavedBrowse>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SavedBrowse, SavedBrowse>,
              SavedBrowse,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
