import '../models/machine.dart';
import '../repositories/endpoint_repository.dart';
import '../repositories/machine_repository.dart';

/// Makes each saved endpoint's `hasApiKey` say whether the key store really
/// holds its key: keys saved in the Keychain (before the key file) didn't come
/// along, and the file can be edited or deleted by hand.
Future<void> syncEndpointKeys(
  EndpointRepository endpoints,
  ApiKeyStore keys,
) async {
  for (final e in await endpoints.watchEndpoints().first) {
    final has = await keys.read(e.id) != null;
    if (has != e.hasApiKey) await endpoints.save(e.copyWith(hasApiKey: has));
  }
}

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
