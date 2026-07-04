import 'package:flutter/widgets.dart';

import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// Provides the design system ([AppColors] + [AppTypography]) to the tree.
///
/// This is a deliberately Material-free theme: no `ThemeData`, no `Theme.of`.
/// Access it with `context.colors` / `context.text`.
class AppTheme extends InheritedWidget {
  AppTheme({super.key, required this.colors, required super.child})
    : text = AppTypography.from(colors);

  final AppColors colors;
  final AppTypography text;

  static AppTheme of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(theme != null, 'No AppTheme found in context');
    return theme!;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => colors != oldWidget.colors;
}

/// Ergonomic access to the theme from any widget.
extension AppThemeContext on BuildContext {
  AppColors get colors => AppTheme.of(this).colors;
  AppTypography get text => AppTheme.of(this).text;
}
