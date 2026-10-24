import 'package:freezed_annotation/freezed_annotation.dart';

import 'perf_report.dart';

part 'settings.freezed.dart';

/// The ShareGPT dataset the benchmarker draws prompts from — where the Perf
/// tab downloads it.
const defaultPerfDatasetPath =
    '~/Library/Application Support/ZML-Lab/'
    'ShareGPT_V3_unfiltered_cleaned_split.json';

/// Where perf runs look for `zml-smi --api` (chip metrics): empty = the
/// target's host on zml-smi's port (see `zmlSmiUrl`).
const defaultChipMetricsUrl = '';

/// The prompt a fresh benchmark run starts with when none is configured.
const defaultBenchmarkPrompt =
    'Summarize the tradeoffs between tensor and pipeline parallelism '
    'for large models.';

/// What "Copy results" fills in until the user writes their own (Slack
/// markdown). Placeholders are listed in `result_template.dart`.
const defaultResultTemplate =
    '*{model}* on {machine}, batch {batch}\n'
    '• Aggregate: *{aggregate_tps} tok/s*\n'
    '• Per request: {avg_tps} tok/s\n'
    '• TTFT: {ttft_ms} ms median, {ttft_p90_ms} ms p90\n'
    '• {ok}/{batch} ok in {elapsed_s} s';

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

    /// Treat Option as Meta in terminals: Option+letter sends `ESC`+letter (so
    /// Option+F/B jump words in zsh) instead of macOS composing a glyph (ƒ, ∫).
    @Default(true) bool terminalOptionAsMeta,

    /// Mask the address in the Benchmark tab's target bar — for screenshots
    /// and screen-sharing. Display only: the real host is still what gets
    /// dialled, and nothing is masked on the way into saved runs.
    @Default(false) bool blurHost,

    // Defaults the benchmark tool starts with.
    @Default(defaultBenchmarkPrompt) String benchPrompt,
    @Default(16) int benchBatchSize,

    /// Null = unlimited (the server stops at EOS or its max seqlen).
    int? benchMaxTokens,

    /// Null = the server's default temperature.
    double? benchTemperature,

    /// Model name sent in benchmark requests (vLLM requires the real one;
    /// llmd ignores it). Empty = send `zml_model`.
    @Default('') String benchModel,

    /// The text "Copy results" puts on the clipboard, with `{placeholders}`
    /// filled from the run — so each person can match their team's format.
    @Default(defaultResultTemplate) String benchCopyTemplate,

    /// Where the perf benchmark's ShareGPT dataset is (or gets downloaded).
    @Default(defaultPerfDatasetPath) String perfDatasetPath,

    /// `zml-smi --api` to sample chip metrics from during perf runs, as typed
    /// in the Perf tab: empty = the target's host, or a port, host:port or
    /// URL (resolved by `zmlSmiUrl`).
    @Default(defaultChipMetricsUrl) String perfChipMetricsUrl,

    /// Last-used perf run parameters — the form remembers them so nothing has
    /// to be re-entered between runs.
    @Default(PerfParams()) PerfParams perfParams,
  }) = _AppSettings;
}

/// Bounds used by both the controller (clamping) and the settings UI.
abstract final class SettingsLimits {
  static const double minTerminalFont = 10;
  static const double maxTerminalFont = 22;
}
