// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The OS appearance, kept live: re-reads whenever macOS switches between
/// light and dark (via a [WidgetsBindingObserver], which composes with other
/// binding observers — unlike claiming `onPlatformBrightnessChanged`).

@ProviderFor(platformBrightness)
final platformBrightnessProvider = PlatformBrightnessProvider._();

/// The OS appearance, kept live: re-reads whenever macOS switches between
/// light and dark (via a [WidgetsBindingObserver], which composes with other
/// binding observers — unlike claiming `onPlatformBrightnessChanged`).

final class PlatformBrightnessProvider
    extends $FunctionalProvider<Brightness, Brightness, Brightness>
    with $Provider<Brightness> {
  /// The OS appearance, kept live: re-reads whenever macOS switches between
  /// light and dark (via a [WidgetsBindingObserver], which composes with other
  /// binding observers — unlike claiming `onPlatformBrightnessChanged`).
  PlatformBrightnessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformBrightnessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformBrightnessHash();

  @$internal
  @override
  $ProviderElement<Brightness> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Brightness create(Ref ref) {
    return platformBrightness(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Brightness value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Brightness>(value),
    );
  }
}

String _$platformBrightnessHash() =>
    r'b64a9ec3cd339ee8201df5d15a39aab07c1621a3';

/// The active palette: the theme-mode setting resolved against the OS
/// appearance (only watched in system mode, so a forced theme doesn't rebuild
/// on OS switches).

@ProviderFor(appColors)
final appColorsProvider = AppColorsProvider._();

/// The active palette: the theme-mode setting resolved against the OS
/// appearance (only watched in system mode, so a forced theme doesn't rebuild
/// on OS switches).

final class AppColorsProvider
    extends $FunctionalProvider<AppColors, AppColors, AppColors>
    with $Provider<AppColors> {
  /// The active palette: the theme-mode setting resolved against the OS
  /// appearance (only watched in system mode, so a forced theme doesn't rebuild
  /// on OS switches).
  AppColorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appColorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appColorsHash();

  @$internal
  @override
  $ProviderElement<AppColors> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppColors create(Ref ref) {
    return appColors(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppColors value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppColors>(value),
    );
  }
}

String _$appColorsHash() => r'56f6b5cc4d796bc1fb1e07bf3f07ad9a7fa76355';
