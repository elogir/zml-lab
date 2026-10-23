// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'benchmark_terminal_panel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keep-alive so the panel's visibility and width survive navigating away.

@ProviderFor(BenchmarkTerminalPanelController)
final benchmarkTerminalPanelControllerProvider =
    BenchmarkTerminalPanelControllerProvider._();

/// Keep-alive so the panel's visibility and width survive navigating away.
final class BenchmarkTerminalPanelControllerProvider
    extends
        $NotifierProvider<
          BenchmarkTerminalPanelController,
          BenchmarkTerminalPanel
        > {
  /// Keep-alive so the panel's visibility and width survive navigating away.
  BenchmarkTerminalPanelControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'benchmarkTerminalPanelControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$benchmarkTerminalPanelControllerHash();

  @$internal
  @override
  BenchmarkTerminalPanelController create() =>
      BenchmarkTerminalPanelController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BenchmarkTerminalPanel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BenchmarkTerminalPanel>(value),
    );
  }
}

String _$benchmarkTerminalPanelControllerHash() =>
    r'99548bff74cd2cf335fe61e68ef9e44792a1fb54';

/// Keep-alive so the panel's visibility and width survive navigating away.

abstract class _$BenchmarkTerminalPanelController
    extends $Notifier<BenchmarkTerminalPanel> {
  BenchmarkTerminalPanel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<BenchmarkTerminalPanel, BenchmarkTerminalPanel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BenchmarkTerminalPanel, BenchmarkTerminalPanel>,
              BenchmarkTerminalPanel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
