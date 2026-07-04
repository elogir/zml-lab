// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'configs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(configsStream)
final configsStreamProvider = ConfigsStreamProvider._();

final class ConfigsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LaunchConfig>>,
          List<LaunchConfig>,
          Stream<List<LaunchConfig>>
        >
    with
        $FutureModifier<List<LaunchConfig>>,
        $StreamProvider<List<LaunchConfig>> {
  ConfigsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<LaunchConfig>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LaunchConfig>> create(Ref ref) {
    return configsStream(ref);
  }
}

String _$configsStreamHash() => r'742b5083c1eeaa37c991ba4f5395ccc0b4c73cc8';
