// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'endpoints_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(endpointsStream)
final endpointsStreamProvider = EndpointsStreamProvider._();

final class EndpointsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ApiEndpoint>>,
          List<ApiEndpoint>,
          Stream<List<ApiEndpoint>>
        >
    with
        $FutureModifier<List<ApiEndpoint>>,
        $StreamProvider<List<ApiEndpoint>> {
  EndpointsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'endpointsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$endpointsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<ApiEndpoint>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ApiEndpoint>> create(Ref ref) {
    return endpointsStream(ref);
  }
}

String _$endpointsStreamHash() => r'e06e0d9353b67d6851084280644a3b7a51cde5ba';

/// id → endpoint, for keeping a selected endpoint in sync with edits.

@ProviderFor(endpointMap)
final endpointMapProvider = EndpointMapProvider._();

/// id → endpoint, for keeping a selected endpoint in sync with edits.

final class EndpointMapProvider
    extends
        $FunctionalProvider<
          Map<String, ApiEndpoint>,
          Map<String, ApiEndpoint>,
          Map<String, ApiEndpoint>
        >
    with $Provider<Map<String, ApiEndpoint>> {
  /// id → endpoint, for keeping a selected endpoint in sync with edits.
  EndpointMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'endpointMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$endpointMapHash();

  @$internal
  @override
  $ProviderElement<Map<String, ApiEndpoint>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, ApiEndpoint> create(Ref ref) {
    return endpointMap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ApiEndpoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ApiEndpoint>>(value),
    );
  }
}

String _$endpointMapHash() => r'e84c60c504f6fb78bc604fa0a4d54bf547fd53ea';
