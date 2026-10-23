// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_mux.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keep-alive so a mux's terminals, web views and layout persist across
/// navigation. Keyed by a caller-chosen id; starts empty and is seeded with a
/// single shell tab by the first [TerminalMux] that mounts it. The sessions
/// live here, not in the widget, so unmounting it doesn't tear them down —
/// only invalidating the provider does.

@ProviderFor(terminalMux)
final terminalMuxProvider = TerminalMuxFamily._();

/// Keep-alive so a mux's terminals, web views and layout persist across
/// navigation. Keyed by a caller-chosen id; starts empty and is seeded with a
/// single shell tab by the first [TerminalMux] that mounts it. The sessions
/// live here, not in the widget, so unmounting it doesn't tear them down —
/// only invalidating the provider does.

final class TerminalMuxProvider
    extends
        $FunctionalProvider<
          TerminalMuxState,
          TerminalMuxState,
          TerminalMuxState
        >
    with $Provider<TerminalMuxState> {
  /// Keep-alive so a mux's terminals, web views and layout persist across
  /// navigation. Keyed by a caller-chosen id; starts empty and is seeded with a
  /// single shell tab by the first [TerminalMux] that mounts it. The sessions
  /// live here, not in the widget, so unmounting it doesn't tear them down —
  /// only invalidating the provider does.
  TerminalMuxProvider._({
    required TerminalMuxFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'terminalMuxProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$terminalMuxHash();

  @override
  String toString() {
    return r'terminalMuxProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TerminalMuxState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TerminalMuxState create(Ref ref) {
    final argument = this.argument as String;
    return terminalMux(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalMuxState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalMuxState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TerminalMuxProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$terminalMuxHash() => r'b71dac6c8bc66117513582c21b482bc4087e6a82';

/// Keep-alive so a mux's terminals, web views and layout persist across
/// navigation. Keyed by a caller-chosen id; starts empty and is seeded with a
/// single shell tab by the first [TerminalMux] that mounts it. The sessions
/// live here, not in the widget, so unmounting it doesn't tear them down —
/// only invalidating the provider does.

final class TerminalMuxFamily extends $Family
    with $FunctionalFamilyOverride<TerminalMuxState, String> {
  TerminalMuxFamily._()
    : super(
        retry: null,
        name: r'terminalMuxProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Keep-alive so a mux's terminals, web views and layout persist across
  /// navigation. Keyed by a caller-chosen id; starts empty and is seeded with a
  /// single shell tab by the first [TerminalMux] that mounts it. The sessions
  /// live here, not in the widget, so unmounting it doesn't tear them down —
  /// only invalidating the provider does.

  TerminalMuxProvider call(String muxId) =>
      TerminalMuxProvider._(argument: muxId, from: this);

  @override
  String toString() => r'terminalMuxProvider';
}
