import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/settings/application/settings_controller.dart';
import '../../models/settings.dart';
import 'app_colors.dart';

part 'theme_controller.g.dart';

/// The OS appearance, kept live: re-reads whenever macOS switches between
/// light and dark (via a [WidgetsBindingObserver], which composes with other
/// binding observers — unlike claiming `onPlatformBrightnessChanged`).
@Riverpod(keepAlive: true)
Brightness platformBrightness(Ref ref) {
  final observer = _BrightnessObserver(ref.invalidateSelf);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  return WidgetsBinding.instance.platformDispatcher.platformBrightness;
}

class _BrightnessObserver with WidgetsBindingObserver {
  _BrightnessObserver(this._onChange);

  final VoidCallback _onChange;

  @override
  void didChangePlatformBrightness() => _onChange();
}

/// The active palette: the theme-mode setting resolved against the OS
/// appearance (only watched in system mode, so a forced theme doesn't rebuild
/// on OS switches).
@Riverpod(keepAlive: true)
AppColors appColors(Ref ref) {
  // Whole-settings watch (no `select` here — that extension ships with
  // flutter_riverpod, not riverpod_annotation): recomputing is trivial and the
  // result is a const palette, so unrelated settings edits don't ripple.
  final mode = ref.watch(settingsControllerProvider).themeMode;
  final brightness = switch (mode) {
    AppThemeMode.system => ref.watch(platformBrightnessProvider),
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
  };
  return brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}
