// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machines_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(machinesStream)
final machinesStreamProvider = MachinesStreamProvider._();

final class MachinesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Machine>>,
          List<Machine>,
          Stream<List<Machine>>
        >
    with $FutureModifier<List<Machine>>, $StreamProvider<List<Machine>> {
  MachinesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'machinesStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$machinesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Machine>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Machine>> create(Ref ref) {
    return machinesStream(ref);
  }
}

String _$machinesStreamHash() => r'c4aaa110d8f39a0e5cf9dba433cc35932824574f';

@ProviderFor(machineStream)
final machineStreamProvider = MachineStreamFamily._();

final class MachineStreamProvider
    extends
        $FunctionalProvider<AsyncValue<Machine?>, Machine?, Stream<Machine?>>
    with $FutureModifier<Machine?>, $StreamProvider<Machine?> {
  MachineStreamProvider._({
    required MachineStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'machineStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$machineStreamHash();

  @override
  String toString() {
    return r'machineStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Machine?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Machine?> create(Ref ref) {
    final argument = this.argument as String;
    return machineStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MachineStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$machineStreamHash() => r'd80442824a190828152e4c96a7c56b3418451a43';

final class MachineStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Machine?>, String> {
  MachineStreamFamily._()
    : super(
        retry: null,
        name: r'machineStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MachineStreamProvider call(String id) =>
      MachineStreamProvider._(argument: id, from: this);

  @override
  String toString() => r'machineStreamProvider';
}

/// Fast id → machine lookup for denormalizing job rows.

@ProviderFor(machineMap)
final machineMapProvider = MachineMapProvider._();

/// Fast id → machine lookup for denormalizing job rows.

final class MachineMapProvider
    extends
        $FunctionalProvider<
          Map<String, Machine>,
          Map<String, Machine>,
          Map<String, Machine>
        >
    with $Provider<Map<String, Machine>> {
  /// Fast id → machine lookup for denormalizing job rows.
  MachineMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'machineMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$machineMapHash();

  @$internal
  @override
  $ProviderElement<Map<String, Machine>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, Machine> create(Ref ref) {
    return machineMap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Machine> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Machine>>(value),
    );
  }
}

String _$machineMapHash() => r'6285cac17f368386f274efbd3d6fff1938688109';
