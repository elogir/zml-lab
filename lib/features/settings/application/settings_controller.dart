import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/perf_report.dart';
import '../../../models/settings.dart';
import '../../../repositories/settings_repository.dart';

part 'settings_controller.g.dart';

/// The live app settings. Starts from built-in defaults; [load] (called once
/// at startup, before the first frame) patches in whatever was persisted.
/// Every setter clamps, updates state, and writes through — a value equal to
/// its default is still stored, only [resetAll] clears the store.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  AppSettings build() => const AppSettings();

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  /// Reads persisted values over the defaults. Unparseable/out-of-range rows
  /// (e.g. from an older build) fall back to the default silently.
  Future<void> load() async {
    final raw = await _repo.all();
    double? d(String k) => double.tryParse(raw[k] ?? '');
    int? i(String k) => int.tryParse(raw[k] ?? '');

    const def = AppSettings();
    state = AppSettings(
      themeMode:
          AppThemeMode.values.asNameMap()[raw['themeMode']] ?? def.themeMode,
      terminalFontSize:
          d('terminalFontSize')?.clamp(
            SettingsLimits.minTerminalFont,
            SettingsLimits.maxTerminalFont,
          ) ??
          def.terminalFontSize,
      terminalOptionAsMeta: switch (raw['terminalOptionAsMeta']) {
        'true' => true,
        'false' => false,
        _ => def.terminalOptionAsMeta,
      },
      blurHost: switch (raw['blurHost']) {
        'true' => true,
        'false' => false,
        _ => def.blurHost,
      },
      benchPrompt: raw['benchPrompt'] ?? def.benchPrompt,
      benchBatchSize: switch (i('benchBatchSize')) {
        null => def.benchBatchSize,
        final n => n < 1 ? 1 : n,
      },
      benchMaxTokens: i('benchMaxTokens'),
      benchTemperature: d('benchTemperature')?.clamp(0.0, 2.0),
      benchModel: raw['benchModel'] ?? def.benchModel,
      benchIgnoreEos: raw['benchIgnoreEos'] == 'true',
      benchCopyTemplate: raw['benchCopyTemplate'] ?? def.benchCopyTemplate,
      perfDatasetPath: raw['perfDatasetPath'] ?? def.perfDatasetPath,
      perfChipMetricsUrl: raw['perfChipMetricsUrl'] ?? def.perfChipMetricsUrl,
      perfZmlSmiPort: switch (i('perfZmlSmiPort')) {
        final n? when n > 0 && n < 65536 => n,
        _ => def.perfZmlSmiPort,
      },
      perfParams: _decodePerfParams(raw['perfParams']) ?? def.perfParams,
    );
    // Settings that no longer exist (the benchmarker's folder, the
    // duckdb copy command).
    for (final key in _retired) {
      if (raw.containsKey(key)) _repo.remove(key);
    }
  }

  static const _retired = ['perfToolDir', 'perfDuckdbCommand'];

  static PerfParams? _decodePerfParams(String? json) {
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      return PerfParams.fromMap(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _repo.put('themeMode', mode.name);
  }

  void setTerminalFontSize(double size) {
    final v = size.clamp(
      SettingsLimits.minTerminalFont,
      SettingsLimits.maxTerminalFont,
    );
    state = state.copyWith(terminalFontSize: v);
    _repo.put('terminalFontSize', '$v');
  }

  void setTerminalOptionAsMeta(bool value) {
    state = state.copyWith(terminalOptionAsMeta: value);
    _repo.put('terminalOptionAsMeta', '$value');
  }

  void setBlurHost(bool value) {
    state = state.copyWith(blurHost: value);
    _repo.put('blurHost', '$value');
  }

  void setBenchPrompt(String prompt) {
    state = state.copyWith(benchPrompt: prompt);
    _repo.put('benchPrompt', prompt);
  }

  void setBenchBatchSize(int size) {
    final v = size < 1 ? 1 : size;
    state = state.copyWith(benchBatchSize: v);
    _repo.put('benchBatchSize', '$v');
  }

  void setBenchMaxTokens(int? tokens) {
    final v = tokens == null || tokens < 1 ? null : tokens;
    state = state.copyWith(benchMaxTokens: v);
    v == null
        ? _repo.remove('benchMaxTokens')
        : _repo.put('benchMaxTokens', '$v');
  }

  void setBenchTemperature(double? temperature) {
    final v = temperature?.clamp(0.0, 2.0);
    state = state.copyWith(benchTemperature: v);
    v == null
        ? _repo.remove('benchTemperature')
        : _repo.put('benchTemperature', '$v');
  }

  /// Empty = send `zml_model` in benchmark requests.
  void setBenchModel(String model) {
    final v = model.trim();
    state = state.copyWith(benchModel: v);
    v.isEmpty ? _repo.remove('benchModel') : _repo.put('benchModel', v);
  }

  void setBenchIgnoreEos(bool on) {
    state = state.copyWith(benchIgnoreEos: on);
    on ? _repo.put('benchIgnoreEos', 'true') : _repo.remove('benchIgnoreEos');
  }

  /// Stored verbatim (whitespace is part of the format). Empty = back to the
  /// default.
  void setBenchCopyTemplate(String template) {
    state = state.copyWith(
      benchCopyTemplate: template.isEmpty ? defaultResultTemplate : template,
    );
    template.isEmpty
        ? _repo.remove('benchCopyTemplate')
        : _repo.put('benchCopyTemplate', template);
  }

  /// Stored as typed; empty is the default (the target's host).
  void setPerfChipMetricsUrl(String url) {
    final v = url.trim();
    state = state.copyWith(perfChipMetricsUrl: v);
    v == defaultChipMetricsUrl
        ? _repo.remove('perfChipMetricsUrl')
        : _repo.put('perfChipMetricsUrl', v);
  }

  /// Null (or out of range) goes back to the default.
  void setPerfZmlSmiPort(int? port) {
    final v = port != null && port > 0 && port < 65536
        ? port
        : defaultZmlSmiPort;
    state = state.copyWith(perfZmlSmiPort: v);
    v == defaultZmlSmiPort
        ? _repo.remove('perfZmlSmiPort')
        : _repo.put('perfZmlSmiPort', '$v');
  }

  void setPerfDatasetPath(String path) {
    final v = path.trim();
    state = state.copyWith(
      perfDatasetPath: v.isEmpty ? defaultPerfDatasetPath : v,
    );
    v.isEmpty
        ? _repo.remove('perfDatasetPath')
        : _repo.put('perfDatasetPath', v);
  }

  /// The perf run parameters — the shared source of truth for both the Perf
  /// tab's form and the Settings defaults. Persisted on every edit in either.
  void setPerfParams(PerfParams params) {
    state = state.copyWith(perfParams: params);
    _repo.put('perfParams', jsonEncode(params.toMap()));
  }

  /// Back to built-in defaults, wiping the store.
  Future<void> resetAll() async {
    await _repo.clear();
    state = const AppSettings();
  }
}
