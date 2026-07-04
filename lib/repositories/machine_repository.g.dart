// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(machineRepository)
final machineRepositoryProvider = MachineRepositoryProvider._();

final class MachineRepositoryProvider
    extends
        $FunctionalProvider<
          MachineRepository,
          MachineRepository,
          MachineRepository
        >
    with $Provider<MachineRepository> {
  MachineRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'machineRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$machineRepositoryHash();

  @$internal
  @override
  $ProviderElement<MachineRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MachineRepository create(Ref ref) {
    return machineRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MachineRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MachineRepository>(value),
    );
  }
}

String _$machineRepositoryHash() => r'96b9587c42d069b1d01d63249830ee9399ebb954';
