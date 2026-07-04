import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/machine.dart';
import '../../../repositories/machine_repository.dart';

part 'machines_providers.g.dart';

@riverpod
Stream<List<Machine>> machinesStream(Ref ref) =>
    ref.watch(machineRepositoryProvider).watchMachines();

@riverpod
Stream<Machine?> machineStream(Ref ref, String id) =>
    ref.watch(machineRepositoryProvider).watchMachine(id);

/// Fast id → machine lookup for denormalizing job rows.
@riverpod
Map<String, Machine> machineMap(Ref ref) {
  final machines = ref.watch(machinesStreamProvider).value ?? const [];
  return {for (final m in machines) m.id: m};
}
