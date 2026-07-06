import 'dart:convert';

import '../core/database/database.dart';
import '../models/benchmark.dart';
import '../models/env_var.dart';
import '../models/enums.dart';
import '../models/job.dart';
import '../models/launch_config.dart';
import '../models/machine.dart';
import '../models/saved_benchmark.dart';

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

BenchmarkRequestStatus _benchmarkStatusFromName(String? name) {
  for (final s in BenchmarkRequestStatus.values) {
    if (s.name == name) return s;
  }
  return BenchmarkRequestStatus.done;
}

/// The benchmark's per-request responses persist as a JSON blob (no codegen on
/// [BenchmarkRequest]); only the display-relevant fields are kept.
String encodeBenchmarkRequests(List<BenchmarkRequest> requests) => jsonEncode([
  for (final r in requests)
    {
      'index': r.index,
      'status': r.status.name,
      'text': r.text,
      if (r.reasoning.isNotEmpty) 'reasoning': r.reasoning,
      'tokens': r.tokens,
      'tokensPerSecond': r.tokensPerSecond,
      'ttftMs': r.ttftMs,
      'latencyMs': r.latencyMs,
    },
]);

/// The throughput time-series persists as a compact JSON blob (see
/// [BenchmarkSample.toMap]).
String encodeBenchmarkSamples(List<BenchmarkSample> samples) =>
    jsonEncode([for (final s in samples) s.toMap()]);

List<BenchmarkSample> decodeBenchmarkSamples(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(BenchmarkSample.fromMap)
      .toList();
}

List<BenchmarkRequest> decodeBenchmarkRequests(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! List) return const [];
  return decoded.whereType<Map<String, dynamic>>().map((m) {
    return BenchmarkRequest(
      index: (m['index'] as num?)?.toInt() ?? 0,
      status: _benchmarkStatusFromName(m['status'] as String?),
      text: m['text'] as String? ?? '',
      reasoning: m['reasoning'] as String? ?? '',
      tokens: (m['tokens'] as num?)?.toInt() ?? 0,
      tokensPerSecond: (m['tokensPerSecond'] as num?)?.toDouble() ?? 0,
      ttftMs: (m['ttftMs'] as num?)?.toInt(),
      latencyMs: (m['latencyMs'] as num?)?.toInt(),
    );
  }).toList();
}

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
    command: command,
    workingDir: workingDir,
    port: port,
    env: decodeEnv(envJson),
  );
}

extension SavedBenchmarkRowMapper on SavedBenchmarkRow {
  SavedBenchmark toModel() => SavedBenchmark(
    id: id,
    name: name,
    endpoint: endpoint,
    machineName: machineName,
    command: command,
    prompt: prompt,
    batchSize: batchSize,
    aggregateTokensPerSecond: aggregateTokensPerSecond,
    completed: completed,
    medianTtftMs: medianTtftMs,
    elapsedMs: elapsedMs,
    createdAt: createdAt,
    requests: decodeBenchmarkRequests(requestsJson),
    samples: decodeBenchmarkSamples(samplesJson),
  );
}

extension JobRowMapper on JobRow {
  Job toModel() => Job(
    id: id,
    name: name,
    description: description,
    machineId: machineId,
    command: command,
    workingDir: workingDir,
    port: port,
    status: _statusFromName(status),
    env: decodeEnv(envJson),
    pid: pid,
    startedAt: startedAt,
  );
}
