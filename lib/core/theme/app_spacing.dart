import 'package:flutter/widgets.dart';

/// Spacing scale (4-pt grid) and shared radii.
///
/// The design leans on generous whitespace, so these are used liberally.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard horizontal padding for a screen's content column.
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: xl,
  );
}

abstract final class AppRadius {
  static const Radius sm = Radius.circular(6);
  static const Radius md = Radius.circular(8);
  static const Radius lg = Radius.circular(12);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius smAll = BorderRadius.all(sm);
  static const BorderRadius mdAll = BorderRadius.all(md);
  static const BorderRadius lgAll = BorderRadius.all(lg);
  static const BorderRadius pillAll = BorderRadius.all(pill);
}

/// Named durations for the app's restrained motion.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
}
