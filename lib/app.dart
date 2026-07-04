import 'package:flutter/material.dart'
    show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

/// Root of the app. Deliberately built on [WidgetsApp] (not `MaterialApp`) so
/// the UI is entirely our own design system. Material *localizations* are
/// provided so the low-level `TextField` (used only for real text selection)
/// works.
class ZmlLabApp extends ConsumerWidget {
  const ZmlLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    return WidgetsApp.router(
      routerConfig: appRouter,
      color: colors.window,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, child) => AppTheme(
        colors: colors,
        child: _RootStyle(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Sets the app-wide default text style and background beneath the router.
class _RootStyle extends StatelessWidget {
  const _RootStyle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.window,
      child: DefaultTextStyle(style: context.text.body, child: child),
    );
  }
}
