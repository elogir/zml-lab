import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/execution/native_io.dart';
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

/// Live reachability of a machine: null while the first probe runs, then a
/// fresh answer every 10s while somebody is watching (auto-dispose stops the
/// polling when no dot is on screen). Local is always reachable; a remote is
/// probed with a silent TCP connect to its ssh port.
@riverpod
Stream<bool?> machineReachable(Ref ref, String machineId) async* {
  yield null;
  while (true) {
    final m = ref.read(machineMapProvider)[machineId];
    final up = m == null
        ? false
        : m.isLocal || await checkHealth(m.address, m.sshPort);
    // The health probe is an async gap during which the provider can be
    // auto-disposed (the dot scrolled off-screen); touching ref then throws.
    if (!ref.mounted) return;
    yield up;
    await Future<void>.delayed(const Duration(seconds: 10));
    // Likewise the 10s wait: bail before the next ref.read if disposed.
    if (!ref.mounted) return;
  }
}
