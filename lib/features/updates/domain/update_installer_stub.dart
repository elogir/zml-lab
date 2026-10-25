import 'update_release.dart';

/// Web stub: the app is served, not installed, so there is nothing to update.
/// Mirrors the native API so the updater compiles on both.
class UpdateInstaller {
  UpdateInstaller._();

  static UpdateInstaller? forThisApp() => null;

  AppVersion? get stagedVersion => null;

  Future<UpdateRelease?> fetchLatest() async => null;

  Future<void> stage(
    UpdateRelease release, {
    void Function(double fraction)? onProgress,
  }) async {}

  Future<void> discard() async {}

  Future<int> armSwap() async => throw UnsupportedError('no updates on web');

  void disarm(int waiter) {}

  Future<Never> restartInto() async =>
      throw UnsupportedError('no updates on web');
}
