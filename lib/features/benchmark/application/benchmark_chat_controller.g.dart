// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'benchmark_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives a chat with a job's endpoint inside the benchmark focus popup. Seeded
/// (per job + request) from the clicked benchmark request; each [send] appends
/// the user's prompt and streams a single reply token-by-token.

@ProviderFor(BenchmarkChatController)
final benchmarkChatControllerProvider = BenchmarkChatControllerFamily._();

/// Drives a chat with a job's endpoint inside the benchmark focus popup. Seeded
/// (per job + request) from the clicked benchmark request; each [send] appends
/// the user's prompt and streams a single reply token-by-token.
final class BenchmarkChatControllerProvider
    extends $NotifierProvider<BenchmarkChatController, BenchmarkChat> {
  /// Drives a chat with a job's endpoint inside the benchmark focus popup. Seeded
  /// (per job + request) from the clicked benchmark request; each [send] appends
  /// the user's prompt and streams a single reply token-by-token.
  BenchmarkChatControllerProvider._({
    required BenchmarkChatControllerFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'benchmarkChatControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$benchmarkChatControllerHash();

  @override
  String toString() {
    return r'benchmarkChatControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  BenchmarkChatController create() => BenchmarkChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BenchmarkChat value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BenchmarkChat>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BenchmarkChatControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$benchmarkChatControllerHash() =>
    r'8865e8c49291a1257c0707fc2f6b0cd260939723';

/// Drives a chat with a job's endpoint inside the benchmark focus popup. Seeded
/// (per job + request) from the clicked benchmark request; each [send] appends
/// the user's prompt and streams a single reply token-by-token.

final class BenchmarkChatControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          BenchmarkChatController,
          BenchmarkChat,
          BenchmarkChat,
          BenchmarkChat,
          (String, int)
        > {
  BenchmarkChatControllerFamily._()
    : super(
        retry: null,
        name: r'benchmarkChatControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives a chat with a job's endpoint inside the benchmark focus popup. Seeded
  /// (per job + request) from the clicked benchmark request; each [send] appends
  /// the user's prompt and streams a single reply token-by-token.

  BenchmarkChatControllerProvider call(String jobId, int index) =>
      BenchmarkChatControllerProvider._(argument: (jobId, index), from: this);

  @override
  String toString() => r'benchmarkChatControllerProvider';
}

/// Drives a chat with a job's endpoint inside the benchmark focus popup. Seeded
/// (per job + request) from the clicked benchmark request; each [send] appends
/// the user's prompt and streams a single reply token-by-token.

abstract class _$BenchmarkChatController extends $Notifier<BenchmarkChat> {
  late final _$args = ref.$arg as (String, int);
  String get jobId => _$args.$1;
  int get index => _$args.$2;

  BenchmarkChat build(String jobId, int index);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BenchmarkChat, BenchmarkChat>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BenchmarkChat, BenchmarkChat>,
              BenchmarkChat,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
