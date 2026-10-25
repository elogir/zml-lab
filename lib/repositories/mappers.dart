import 'dart:convert';

import '../core/database/database.dart';
import '../models/benchmark.dart';
import '../models/enums.dart';
import '../models/machine.dart';
import '../models/perf_report.dart';
import '../models/saved_benchmark.dart';

/// Conversions between drift rows and the domain models the UI consumes.
///
/// Enums are persisted as their `name`.

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
      if (r.finishReason != null) 'finishReason': r.finishReason,
      if (r.error != null) 'error': r.error,
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
      finishReason: m['finishReason'] as String?,
      error: m['error'] as String?,
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

extension MachineRowMapper on MachineRow {
  Machine toModel() => Machine(
    id: id,
    name: name,
    address: address,
    vendor: _vendorFromName(vendor),
    gpus: gpus,
    memory: memory,
    online: online,
  );
}

extension SavedBenchmarkRowMapper on SavedBenchmarkRow {
  SavedBenchmark toModel() => SavedBenchmark(
    id: id,
    name: name,
    endpoint: endpoint,
    machineName: machineName,
    prompt: prompt,
    model: model,
    modelAlias: modelAlias,
    notes: notes,
    maxTokens: maxTokens,
    temperature: temperature,
    ignoreEos: ignoreEos,
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

extension PerfReportRowMapper on PerfReportRow {
  PerfReport toModel() {
    final decoded = jsonDecode(reportJson);
    return PerfReport.fromParts(
      id: id,
      name: name,
      machineName: machineName,
      endpoint: endpoint,
      createdAt: createdAt,
      totalRequests: totalRequests,
      tokensPerSecond: tokensPerSecond,
      requestsPerSecond: requestsPerSecond,
      m: decoded is Map ? decoded.cast<String, dynamic>() : const {},
    );
  }
}
