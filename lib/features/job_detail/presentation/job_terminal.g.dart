// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_terminal.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keep-alive so a job's terminals, web views and layout persist across
/// navigation. Keyed by job id; seeded with a single shell tab on first read.
/// The sessions live here, not in [JobTerminal], so unmounting the widget no
/// longer tears them down — only invalidating the provider does.

@ProviderFor(terminalMux)
final terminalMuxProvider = TerminalMuxFamily._();

/// Keep-alive so a job's terminals, web views and layout persist across
/// navigation. Keyed by job id; seeded with a single shell tab on first read.
/// The sessions live here, not in [JobTerminal], so unmounting the widget no
/// longer tears them down — only invalidating the provider does.

final class TerminalMuxProvider
    extends
        $FunctionalProvider<
          TerminalMuxState,
          TerminalMuxState,
          TerminalMuxState
        >
    with $Provider<TerminalMuxState> {
  /// Keep-alive so a job's terminals, web views and layout persist across
  /// navigation. Keyed by job id; seeded with a single shell tab on first read.
  /// The sessions live here, not in [JobTerminal], so unmounting the widget no
  /// longer tears them down — only invalidating the provider does.
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

String _$terminalMuxHash() => r'3eec5503072f1a52c79bf9169ad84807705ab38c';

/// Keep-alive so a job's terminals, web views and layout persist across
/// navigation. Keyed by job id; seeded with a single shell tab on first read.
/// The sessions live here, not in [JobTerminal], so unmounting the widget no
/// longer tears them down — only invalidating the provider does.

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

  /// Keep-alive so a job's terminals, web views and layout persist across
  /// navigation. Keyed by job id; seeded with a single shell tab on first read.
  /// The sessions live here, not in [JobTerminal], so unmounting the widget no
  /// longer tears them down — only invalidating the provider does.

  TerminalMuxProvider call(String jobId) =>
      TerminalMuxProvider._(argument: jobId, from: this);

  @override
  String toString() => r'terminalMuxProvider';
}
