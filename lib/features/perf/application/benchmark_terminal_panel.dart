import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'benchmark_terminal_panel.g.dart';

/// The terminal panel beside the Benchmark tab's tools: whether it's shown,
/// and the share of the width it takes. Starts closed: the toggle opens it.
class BenchmarkTerminalPanel {
  const BenchmarkTerminalPanel({this.open = false, this.ratio = 0.45});

  final bool open;

  /// Terminal width as a fraction of the space the tools and terminal share.
  final double ratio;

  static const minRatio = 0.2;
  static const maxRatio = 0.8;
}

/// Keep-alive so the panel's visibility and width survive navigating away.
@Riverpod(keepAlive: true)
class BenchmarkTerminalPanelController
    extends _$BenchmarkTerminalPanelController {
  @override
  BenchmarkTerminalPanel build() => const BenchmarkTerminalPanel();

  void toggle() => state = BenchmarkTerminalPanel(
    open: !state.open,
    ratio: state.ratio,
  );

  void setRatio(double ratio) => state = BenchmarkTerminalPanel(
    open: state.open,
    ratio: ratio.clamp(
      BenchmarkTerminalPanel.minRatio,
      BenchmarkTerminalPanel.maxRatio,
    ),
  );
}
