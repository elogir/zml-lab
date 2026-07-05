import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/execution/native_io.dart';
import '../../../repositories/config_repository.dart';
import '../../../repositories/job_repository.dart';
import '../../machines/application/machines_providers.dart';
import '../../settings/application/settings_controller.dart';

/// Finds a free port for [machineId] within the configured range, avoiding the
/// ports ZML-Lab already knows are in use on that machine: the ports of its
/// saved configs and its active jobs (plus anything in [alsoAvoid], e.g. the
/// port a config is being duplicated from).
///
/// For the local machine it also does a real bind test (via [findFreePort]) to
/// skip ports something else on this Mac is using. For a remote machine a local
/// probe would be meaningless, so it just picks the first port the fleet hasn't
/// claimed on that host.
Future<int> freePortForMachine(
  WidgetRef ref,
  String machineId, {
  Set<int> alsoAvoid = const {},
}) async {
  final jobs = await ref.read(jobRepositoryProvider).allJobs();
  final configs = await ref.read(configRepositoryProvider).allConfigs();
  final s = ref.read(settingsControllerProvider);
  final start = s.portRangeStart;
  final end = s.portRangeEnd > s.portRangeStart
      ? s.portRangeEnd
      : s.portRangeStart + 1;

  final taken = <int>{
    ...alsoAvoid,
    for (final j in jobs)
      if (j.machineId == machineId && j.status.isActive) j.port,
    for (final c in configs)
      if (c.machineId == machineId) c.port,
  };

  final machine = ref.read(machineMapProvider)[machineId];
  if (machine == null || machine.isLocal) {
    return findFreePort(start: start, end: end, avoid: taken);
  }
  for (var p = start; p < end; p++) {
    if (!taken.contains(p)) return p;
  }
  return start;
}
