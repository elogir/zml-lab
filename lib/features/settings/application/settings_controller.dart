import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      portRangeStart:
          i('portRangeStart')?.clamp(
            SettingsLimits.minPort,
            SettingsLimits.maxPort,
          ) ??
          def.portRangeStart,
      portRangeEnd:
          i('portRangeEnd')?.clamp(
            SettingsLimits.minPort,
            SettingsLimits.maxPort,
          ) ??
          def.portRangeEnd,
      healthIntervalSeconds:
          i('healthIntervalSeconds')?.clamp(
            SettingsLimits.minHealthInterval,
            SettingsLimits.maxHealthInterval,
          ) ??
          def.healthIntervalSeconds,
      benchPrompt: raw['benchPrompt'] ?? def.benchPrompt,
      benchBatchSize: switch (i('benchBatchSize')) {
        null => def.benchBatchSize,
        final n => n < 1 ? 1 : n,
      },
      benchMaxTokens: i('benchMaxTokens'),
      benchTemperature: d('benchTemperature')?.clamp(0.0, 2.0),
    );
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

  void setPortRangeStart(int port) {
    final v = port.clamp(SettingsLimits.minPort, SettingsLimits.maxPort);
    state = state.copyWith(portRangeStart: v);
    _repo.put('portRangeStart', '$v');
  }

  void setPortRangeEnd(int port) {
    final v = port.clamp(SettingsLimits.minPort, SettingsLimits.maxPort);
    state = state.copyWith(portRangeEnd: v);
    _repo.put('portRangeEnd', '$v');
  }

  void setHealthInterval(int seconds) {
    final v = seconds.clamp(
      SettingsLimits.minHealthInterval,
      SettingsLimits.maxHealthInterval,
    );
    state = state.copyWith(healthIntervalSeconds: v);
    _repo.put('healthIntervalSeconds', '$v');
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
    v == null ? _repo.remove('benchMaxTokens') : _repo.put('benchMaxTokens', '$v');
  }

  void setBenchTemperature(double? temperature) {
    final v = temperature?.clamp(0.0, 2.0);
    state = state.copyWith(benchTemperature: v);
    v == null
        ? _repo.remove('benchTemperature')
        : _repo.put('benchTemperature', '$v');
  }

  /// Back to built-in defaults, wiping the store.
  Future<void> resetAll() async {
    await _repo.clear();
    state = const AppSettings();
  }
}
