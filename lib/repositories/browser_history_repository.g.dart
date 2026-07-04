// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_history_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(browserHistoryRepository)
final browserHistoryRepositoryProvider = BrowserHistoryRepositoryProvider._();

final class BrowserHistoryRepositoryProvider
    extends
        $FunctionalProvider<
          BrowserHistoryRepository,
          BrowserHistoryRepository,
          BrowserHistoryRepository
        >
    with $Provider<BrowserHistoryRepository> {
  BrowserHistoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browserHistoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browserHistoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<BrowserHistoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BrowserHistoryRepository create(Ref ref) {
    return browserHistoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrowserHistoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrowserHistoryRepository>(value),
    );
  }
}

String _$browserHistoryRepositoryHash() =>
    r'1f1d9460b8a03692754874097690432985b4b5c8';
