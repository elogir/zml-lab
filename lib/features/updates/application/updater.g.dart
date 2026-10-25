// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'updater.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Checks GitHub for new releases (shortly after launch, then every few
/// hours), downloads and stages them beside the app, and offers "Restart to
/// update". With auto update on it also arms the swap, so a staged build goes
/// in when the app quits.

@ProviderFor(Updater)
final updaterProvider = UpdaterProvider._();

/// Checks GitHub for new releases (shortly after launch, then every few
/// hours), downloads and stages them beside the app, and offers "Restart to
/// update". With auto update on it also arms the swap, so a staged build goes
/// in when the app quits.
final class UpdaterProvider extends $NotifierProvider<Updater, UpdateStatus> {
  /// Checks GitHub for new releases (shortly after launch, then every few
  /// hours), downloads and stages them beside the app, and offers "Restart to
  /// update". With auto update on it also arms the swap, so a staged build goes
  /// in when the app quits.
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

String _$updaterHash() => r'39798d7f74ea8ec70efb67e8dc07f6a69ea6f2a2';

/// Checks GitHub for new releases (shortly after launch, then every few
/// hours), downloads and stages them beside the app, and offers "Restart to
/// update". With auto update on it also arms the swap, so a staged build goes
/// in when the app quits.

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
