import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_colors.dart';

part 'theme_controller.g.dart';

/// App brightness. Defaults to dark (the shipped design); light is ready.
@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  Brightness build() => Brightness.dark;

  void toggle() => state = state == Brightness.dark
      ? Brightness.light
      : Brightness.dark;
}

/// The active palette, derived from the current brightness.
@riverpod
AppColors appColors(Ref ref) =>
    ref.watch(themeModeControllerProvider) == Brightness.dark
    ? AppColors.dark
    : AppColors.light;
