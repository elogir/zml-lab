// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live app settings. Starts from built-in defaults; [load] (called once
/// at startup, before the first frame) patches in whatever was persisted.
/// Every setter clamps, updates state, and writes through — a value equal to
/// its default is still stored, only [resetAll] clears the store.

@ProviderFor(SettingsController)
final settingsControllerProvider = SettingsControllerProvider._();

/// The live app settings. Starts from built-in defaults; [load] (called once
/// at startup, before the first frame) patches in whatever was persisted.
/// Every setter clamps, updates state, and writes through — a value equal to
/// its default is still stored, only [resetAll] clears the store.
final class SettingsControllerProvider
    extends $NotifierProvider<SettingsController, AppSettings> {
  /// The live app settings. Starts from built-in defaults; [load] (called once
  /// at startup, before the first frame) patches in whatever was persisted.
  /// Every setter clamps, updates state, and writes through — a value equal to
  /// its default is still stored, only [resetAll] clears the store.
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettings>(value),
    );
  }
}

String _$settingsControllerHash() =>
    r'a7734d17342cb04860e543178d5113048181c9d7';

/// The live app settings. Starts from built-in defaults; [load] (called once
/// at startup, before the first frame) patches in whatever was persisted.
/// Every setter clamps, updates state, and writes through — a value equal to
/// its default is still stored, only [resetAll] clears the store.

abstract class _$SettingsController extends $Notifier<AppSettings> {
  AppSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppSettings, AppSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppSettings, AppSettings>,
              AppSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
