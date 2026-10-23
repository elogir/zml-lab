import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_icon_button.dart';
import 'app_icons.dart';
import 'surface.dart';

/// Shows [builder] as a centred modal over a dimmed backdrop (tap outside to
/// dismiss), with the app's fade-and-settle entrance. Pop with a value to
/// return it.
Future<T?> showAppDialog<T>(BuildContext context, WidgetBuilder builder) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      barrierLabel: 'Dismiss',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => builder(context),
      transitionsBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// The panel a dialog sits in: an icon + title row with a close button, the
/// [body], and right-aligned [actions].
class AppDialogFrame extends StatelessWidget {
  const AppDialogFrame({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
    this.maxWidth = 460,
  });

  final IconData icon;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppPanel(
            color: c.surface,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: c.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(title, style: context.text.bodyStrong),
                    ),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                body,
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    const Spacer(),
                    for (final (i, a) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      a,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks [message] with Cancel / [confirmLabel]; true only on confirm.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = AppIcons.warning,
}) async {
  final ok = await showAppDialog<bool>(
    context,
    (context) => AppDialogFrame(
      icon: icon,
      title: title,
      body: Text(message, style: context.text.bodySecondary),
      actions: [
        AppButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return ok ?? false;
}
