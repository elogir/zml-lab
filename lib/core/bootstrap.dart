import '../models/machine.dart';
import '../repositories/machine_repository.dart';

/// Ensures a machine representing the computer the app runs on exists, so jobs
/// can be launched locally (no SSH) out of the box. Idempotent, and a no-op
/// once any local machine is present — so renames/edits to it stick.
Future<void> ensureLocalMachine(MachineRepository machines) async {
  final all = await machines.allMachines();
  if (all.any((m) => m.isLocal)) return;
  await machines.upsertMachine(
    const Machine(
      id: 'local',
      name: 'local',
      address: 'localhost',
      gpus: 'Apple Silicon (Metal)',
    ),
  );
}
