import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zml_lab/core/shell/app_fullscreen.dart';
import 'package:zml_lab/features/perf/application/benchmark_terminal_panel.dart';

void main() {
  test('a view tearing down only drops its own fullscreen', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final fullscreen = container.read(appFullscreenProvider.notifier);

    fullscreen.toggle(FullscreenSurface.perf);
    fullscreen.exitIf(FullscreenSurface.terminal);
    expect(container.read(appFullscreenProvider), FullscreenSurface.perf);

    fullscreen.toggle(FullscreenSurface.terminal);
    expect(container.read(appFullscreenProvider), FullscreenSurface.terminal);
    fullscreen.exitIf(FullscreenSurface.terminal);
    expect(container.read(appFullscreenProvider), isNull);
  });

  test('terminal panel width stays within bounds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final panel = container.read(
      benchmarkTerminalPanelControllerProvider.notifier,
    );
    // Hidden until asked for.
    expect(
      container.read(benchmarkTerminalPanelControllerProvider).open,
      isFalse,
    );

    panel.setRatio(2);
    expect(
      container.read(benchmarkTerminalPanelControllerProvider).ratio,
      BenchmarkTerminalPanel.maxRatio,
    );
    panel.toggle();
    final state = container.read(benchmarkTerminalPanelControllerProvider);
    expect(state.open, isTrue);
    expect(state.ratio, BenchmarkTerminalPanel.maxRatio);
  });
}
