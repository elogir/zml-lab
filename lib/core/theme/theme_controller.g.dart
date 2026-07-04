// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App brightness. Defaults to dark (the shipped design); light is ready.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// App brightness. Defaults to dark (the shipped design); light is ready.
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, Brightness> {
  /// App brightness. Defaults to dark (the shipped design); light is ready.
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Brightness value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Brightness>(value),
    );
  }
}

String _$themeModeControllerHash() =>
    r'2744526fd6f6fb02159614ed3d91cbac8ea6454d';

/// App brightness. Defaults to dark (the shipped design); light is ready.

abstract class _$ThemeModeController extends $Notifier<Brightness> {
  Brightness build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Brightness, Brightness>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Brightness, Brightness>,
              Brightness,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The active palette, derived from the current brightness.

@ProviderFor(appColors)
final appColorsProvider = AppColorsProvider._();

/// The active palette, derived from the current brightness.

final class AppColorsProvider
    extends $FunctionalProvider<AppColors, AppColors, AppColors>
    with $Provider<AppColors> {
  /// The active palette, derived from the current brightness.
  AppColorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appColorsProvider',
        isAutoDispose: true,
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

String _$appColorsHash() => r'0d091cfb0c39b47ecf227d15151bd859c00b0ad0';
