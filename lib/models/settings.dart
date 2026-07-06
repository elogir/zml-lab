import 'package:freezed_annotation/freezed_annotation.dart';

import 'env_var.dart';

part 'settings.freezed.dart';

/// The prompt a fresh benchmark run starts with when none is configured.
const defaultBenchmarkPrompt =
    'Summarize the tradeoffs between tensor and pipeline parallelism '
    'for large models.';

/// How the app picks its palette.
enum AppThemeMode {
  system,
  light,
  dark;

  String get label => switch (this) {
    AppThemeMode.system => 'System',
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
  };
}

/// App-wide preferences. Every field has a built-in default; the settings
/// store only persists values that differ from it.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,

    /// Terminal text size (flterm renders from font data, not app text styles).
    @Default(14.0) double terminalFontSize,

    /// The range `findFreePort` scans when pre-filling a new job's port.
    @Default(8000) int portRangeStart,
    @Default(8100) int portRangeEnd,

    /// Seconds between endpoint health checks on running jobs.
    @Default(5) int healthIntervalSeconds,

    // Defaults a job's benchmark tab starts with.
    @Default(defaultBenchmarkPrompt) String benchPrompt,
    @Default(16) int benchBatchSize,

    /// Null = unlimited (the server stops at EOS or its max seqlen).
    int? benchMaxTokens,

    /// Null = the server's default temperature.
    double? benchTemperature,

    /// Environment variables injected into every job launch (local and remote).
    /// A job's own env vars override these on a key clash.
    @Default(<EnvVar>[]) List<EnvVar> globalEnv,
  }) = _AppSettings;
}

/// Bounds used by both the controller (clamping) and the settings UI.
abstract final class SettingsLimits {
  static const double minTerminalFont = 10;
  static const double maxTerminalFont = 22;
  static const int minHealthInterval = 2;
  static const int maxHealthInterval = 60;
  static const int minPort = 1024;
  static const int maxPort = 65535;
}
