// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'updater.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Checks GitHub for new releases (shortly after launch, then every few
/// hours). With auto update on, a new release downloads and stages beside the
/// app right away, the swap is armed so it goes in when the app quits, and
/// "Restart to update" installs it sooner. With it off, the sidebar offers
/// "Update to …", which downloads it and then restarts into it.

@ProviderFor(Updater)
final updaterProvider = UpdaterProvider._();

/// Checks GitHub for new releases (shortly after launch, then every few
/// hours). With auto update on, a new release downloads and stages beside the
/// app right away, the swap is armed so it goes in when the app quits, and
/// "Restart to update" installs it sooner. With it off, the sidebar offers
/// "Update to …", which downloads it and then restarts into it.
final class UpdaterProvider extends $NotifierProvider<Updater, UpdateStatus> {
  /// Checks GitHub for new releases (shortly after launch, then every few
  /// hours). With auto update on, a new release downloads and stages beside the
  /// app right away, the swap is armed so it goes in when the app quits, and
  /// "Restart to update" installs it sooner. With it off, the sidebar offers
  /// "Update to …", which downloads it and then restarts into it.
  UpdaterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updaterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updaterHash();

  @$internal
  @override
  Updater create() => Updater();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateStatus>(value),
    );
  }
}

String _$updaterHash() => r'ece52253ef6653004c29ace563f6a04cb97e344b';

/// Checks GitHub for new releases (shortly after launch, then every few
/// hours). With auto update on, a new release downloads and stages beside the
/// app right away, the swap is armed so it goes in when the app quits, and
/// "Restart to update" installs it sooner. With it off, the sidebar offers
/// "Update to …", which downloads it and then restarts into it.

abstract class _$Updater extends $Notifier<UpdateStatus> {
  UpdateStatus build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UpdateStatus, UpdateStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateStatus, UpdateStatus>,
              UpdateStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
