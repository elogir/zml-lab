import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The app's type ramp.
///
/// Two families, per the brief:
///  - **Inter** for prose / UI chrome (via google_fonts).
///  - **JetBrains Mono** (bundled) for anything "machine-ish": hostnames,
///    ports, paths, commands, log output, metrics.
///
/// Built from [AppColors] so every style carries a sensible default color.
@immutable
class AppTypography {
  const AppTypography({
    required this.title,
    required this.subtitle,
    required this.sectionLabel,
    required this.columnHeader,
    required this.bodyStrong,
    required this.body,
    required this.bodySecondary,
    required this.small,
    required this.smallMuted,
    required this.mono,
    required this.monoSecondary,
    required this.monoSmall,
    required this.monoBadge,
    required this.button,
  });

  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle sectionLabel;
  final TextStyle columnHeader;
  final TextStyle bodyStrong;
  final TextStyle body;
  final TextStyle bodySecondary;
  final TextStyle small;
  final TextStyle smallMuted;
  final TextStyle mono;
  final TextStyle monoSecondary;
  final TextStyle monoSmall;
  final TextStyle monoBadge;
  final TextStyle button;

  static const String monoFamily = 'JetBrains Mono';

  factory AppTypography.from(AppColors c) {
    TextStyle sans(
      double size,
      FontWeight weight,
      Color color, {
      double? spacing,
      double height = 1.4,
    }) => GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

    TextStyle monoStyle(
      double size,
      FontWeight weight,
      Color color, {
      double height = 1.45,
    }) => TextStyle(
      fontFamily: monoFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

    return AppTypography(
      title: sans(22, FontWeight.w600, c.textPrimary, height: 1.2),
      subtitle: sans(13, FontWeight.w400, c.textMuted),
      sectionLabel: sans(
        11,
        FontWeight.w600,
        c.textFaint,
        spacing: 0.8,
        height: 1.2,
      ),
      columnHeader: sans(
        11,
        FontWeight.w500,
        c.textFaint,
        spacing: 0.6,
        height: 1.2,
      ),
      bodyStrong: sans(15, FontWeight.w600, c.textPrimary, height: 1.3),
      body: sans(13, FontWeight.w400, c.textPrimary),
      bodySecondary: sans(13, FontWeight.w400, c.textSecondary),
      small: sans(12, FontWeight.w400, c.textSecondary),
      smallMuted: sans(12, FontWeight.w400, c.textMuted),
      mono: monoStyle(13, FontWeight.w400, c.textPrimary),
      monoSecondary: monoStyle(13, FontWeight.w400, c.textSecondary),
      monoSmall: monoStyle(12, FontWeight.w400, c.textMuted),
      monoBadge: monoStyle(11, FontWeight.w500, c.textSecondary, height: 1.0),
      button: sans(13, FontWeight.w500, c.textPrimary, height: 1.0),
    );
  }
}
