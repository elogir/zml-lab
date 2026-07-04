import 'dart:convert';

import '../core/database/database.dart';
import '../models/env_var.dart';
import '../models/enums.dart';
import '../models/job.dart';
import '../models/launch_config.dart';
import '../models/machine.dart';

/// Conversions between drift rows and the domain models the UI consumes.
///
/// Env vars are persisted as a JSON blob; enums as their `name`.

List<EnvVar> decodeEnv(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(EnvVar.fromJson)
      .toList();
}

String encodeEnv(List<EnvVar> env) =>
    jsonEncode(env.map((e) => e.toJson()).toList());

Vendor? _vendorFromName(String? name) {
  if (name == null) return null;
  for (final v in Vendor.values) {
    if (v.name == name) return v;
  }
  return null;
}

JobStatus _statusFromName(String name) {
  for (final s in JobStatus.values) {
    if (s.name == name) return s;
  }
  return JobStatus.exited;
}

extension MachineRowMapper on MachineRow {
  Machine toModel() => Machine(
    id: id,
    name: name,
    address: address,
    sshPort: sshPort,
    user: user,
    sshKey: sshKey,
    vendor: _vendorFromName(vendor),
    gpus: gpus,
    memory: memory,
    online: online,
  );
}

extension LaunchConfigRowMapper on LaunchConfigRow {
  LaunchConfig toModel() => LaunchConfig(
    id: id,
    name: name,
    description: description,
    machineId: machineId,
    program: program,
    command: command,
    workingDir: workingDir,
    port: port,
    env: decodeEnv(envJson),
  );
}

extension JobRowMapper on JobRow {
  Job toModel() => Job(
    id: id,
    name: name,
    description: description,
    machineId: machineId,
    program: program,
    command: command,
    workingDir: workingDir,
    port: port,
    status: _statusFromName(status),
    env: decodeEnv(envJson),
    pid: pid,
    startedAt: startedAt,
  );
}
