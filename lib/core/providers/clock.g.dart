// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A once-per-second wall-clock tick. Widgets that show live uptime watch
/// this so only they rebuild, not the lists that contain them.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// A once-per-second wall-clock tick. Widgets that show live uptime watch
/// this so only they rebuild, not the lists that contain them.

final class ClockProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// A once-per-second wall-clock tick. Widgets that show live uptime watch
  /// this so only they rebuild, not the lists that contain them.
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return clock(ref);
  }
}

String _$clockHash() => r'e06104e9c5897c3e49c7be1061a691804c77c16e';
