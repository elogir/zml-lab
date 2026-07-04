import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Semantic color tokens for the whole app.
///
/// Everything visual references these names — never a raw hex — so a light
/// theme is a drop-in swap and the palette can be retuned in one place.
///
/// The palette is a restrained, GitHub-dark-flavored set. Color is reserved
/// almost entirely for status; surfaces are near-monochrome.
@immutable
class AppColors {
  const AppColors({
    required this.brightness,
    required this.window,
    required this.titleBar,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceHover,
    required this.surfaceSelected,
    required this.border,
    required this.borderMuted,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.statusRunning,
    required this.statusStarting,
    required this.statusFailed,
    required this.statusExited,
    required this.primaryButtonBg,
    required this.primaryButtonFg,
    required this.terminalBackground,
    required this.terminalBorder,
    required this.trafficRed,
    required this.trafficYellow,
    required this.trafficGreen,
  });

  final Brightness brightness;

  /// Outermost desktop-window background.
  final Color window;

  /// The custom title bar strip.
  final Color titleBar;

  /// Raised panels, cards, list containers.
  final Color surface;

  /// Slightly recessed surface (inputs, inner wells).
  final Color surfaceMuted;

  /// Hover state for interactive rows/cards.
  final Color surfaceHover;

  /// Selected / active surface (nav item, chosen card).
  final Color surfaceSelected;

  /// Default hairline border.
  final Color border;

  /// Barely-there divider.
  final Color borderMuted;

  /// Emphasized border (focus ring, selected card outline).
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// For column headers, disabled, placeholder.
  final Color textFaint;

  /// The single non-status accent (links, focus, info).
  final Color accent;

  // Status — the only place color really earns its keep.
  final Color statusRunning;
  final Color statusStarting;
  final Color statusFailed;
  final Color statusExited;

  /// Primary action button (near-inverse of the surface).
  final Color primaryButtonBg;
  final Color primaryButtonFg;

  /// Terminal pane background (usually a touch darker than surface).
  final Color terminalBackground;

  /// A distinctly-visible border for the terminal chrome, which otherwise
  /// blends into the near-black background.
  final Color terminalBorder;

  // macOS-style window control dots.
  final Color trafficRed;
  final Color trafficYellow;
  final Color trafficGreen;

  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    window: Color(0xFF0B0C0F),
    titleBar: Color(0xFF0E0F13),
    surface: Color(0xFF121419),
    surfaceMuted: Color(0xFF0D0F13),
    surfaceHover: Color(0xFF171A20),
    surfaceSelected: Color(0xFF1B1E24),
    border: Color(0xFF21262D),
    borderMuted: Color(0xFF191C22),
    borderStrong: Color(0xFF2A2E37),
    textPrimary: Color(0xFFE6E8EB),
    textSecondary: Color(0xFF9198A1),
    textMuted: Color(0xFF656C76),
    textFaint: Color(0xFF4D545D),
    accent: Color(0xFF6EA8FF),
    statusRunning: Color(0xFF3FB950),
    statusStarting: Color(0xFFD29922),
    statusFailed: Color(0xFFF85149),
    statusExited: Color(0xFF8A919B),
    primaryButtonBg: Color(0xFFE6E8EB),
    primaryButtonFg: Color(0xFF0B0C0F),
    terminalBackground: Color(0xFF0B0C0E),
    terminalBorder: Color(0xFF3B424E),
    trafficRed: Color(0xFFFF5F57),
    trafficYellow: Color(0xFFFEBC2E),
    trafficGreen: Color(0xFF28C840),
  );

  /// Light theme — structurally complete so a theme toggle works today.
  /// It is deliberately conservative; the mockup ships dark.
  static const AppColors light = AppColors(
    brightness: Brightness.light,
    window: Color(0xFFF6F7F9),
    titleBar: Color(0xFFECEEF1),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF2F3F5),
    surfaceHover: Color(0xFFF0F1F4),
    surfaceSelected: Color(0xFFEAECEF),
    border: Color(0xFFD5DAE0),
    borderMuted: Color(0xFFE4E7EB),
    borderStrong: Color(0xFFC2C8D0),
    textPrimary: Color(0xFF16181D),
    textSecondary: Color(0xFF565D66),
    textMuted: Color(0xFF828A94),
    textFaint: Color(0xFFA5ADB6),
    accent: Color(0xFF2563EB),
    statusRunning: Color(0xFF1A7F37),
    statusStarting: Color(0xFF9A6700),
    statusFailed: Color(0xFFCF222E),
    statusExited: Color(0xFF8A919B),
    primaryButtonBg: Color(0xFF16181D),
    primaryButtonFg: Color(0xFFFFFFFF),
    terminalBackground: Color(0xFF0B0C0E),
    terminalBorder: Color(0xFF3B424E),
    trafficRed: Color(0xFFFF5F57),
    trafficYellow: Color(0xFFFEBC2E),
    trafficGreen: Color(0xFF28C840),
  );
}
