// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'endpoint_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(endpointRepository)
final endpointRepositoryProvider = EndpointRepositoryProvider._();

final class EndpointRepositoryProvider
    extends
        $FunctionalProvider<
          EndpointRepository,
          EndpointRepository,
          EndpointRepository
        >
    with $Provider<EndpointRepository> {
  EndpointRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'endpointRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$endpointRepositoryHash();

  @$internal
  @override
  $ProviderElement<EndpointRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EndpointRepository create(Ref ref) {
    return endpointRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EndpointRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EndpointRepository>(value),
    );
  }
}

String _$endpointRepositoryHash() =>
    r'1d72f97d4d127185af68a11103d2604ae189171f';

@ProviderFor(apiKeyStore)
final apiKeyStoreProvider = ApiKeyStoreProvider._();

final class ApiKeyStoreProvider
    extends $FunctionalProvider<ApiKeyStore, ApiKeyStore, ApiKeyStore>
    with $Provider<ApiKeyStore> {
  ApiKeyStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeyStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeyStoreHash();

  @$internal
  @override
  $ProviderElement<ApiKeyStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiKeyStore create(Ref ref) {
    return apiKeyStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiKeyStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiKeyStore>(value),
    );
  }
}

String _$apiKeyStoreHash() => r'5d3febfb520d0791274b99c6298fdc3115a63562';
