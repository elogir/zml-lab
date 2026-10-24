/// zml-smi (`--api`) during perf runs: where to find it, and what a run's
/// samples add up to for the report. Definitions are the run format's
/// (docs/perf-run-format.md, "Metrics"; checked against its SQL in
/// test/perf_contract_test.dart).
library;

import 'dart:math' as math;

import '../../../models/perf_report.dart';
import '../../../models/settings.dart';
import 'run_recorder_types.dart';

/// zml-smi's URL for a run against [host], from the Metrics popover's
/// setting: empty is [host] on [port] (the Settings default); a port
/// (`9091`, `:9091`) is [host] on that port; a host, host:port or URL is
/// taken as given (on [port] when it names none). `{host}` in it stands for
/// [host].
String zmlSmiUrl(String setting, String host, {int port = defaultZmlSmiPort}) {
  var s = setting.trim().replaceAll('{host}', host);
  if (s.isEmpty) return 'http://$host:$port';
  if (RegExp(r'^:?(\d+)$').firstMatch(s) case final port?) {
    return 'http://$host:${port[1]}';
  }
  if (!s.contains('://')) s = 'http://$s';
  final start = s.indexOf('://') + 3;
  final authority = RegExp(r'^[^/?#]*').stringMatch(s.substring(start)) ?? '';
  if (RegExp(r':\d+$').hasMatch(authority)) return s;
  final end = start + authority.length;
  return '${s.substring(0, end)}:$port${s.substring(end)}';
}

/// [chips] as people name hardware: `2× NVIDIA H100 80GB HBM3`, grouped by
/// model in device order.
String describeChips(List<ChipReading> chips) {
  final counts = <String, int>{};
  for (final c in chips) {
    final name = c.name ?? c.kind;
    counts[name] = (counts[name] ?? 0) + 1;
  }
  return [
    for (final MapEntry(:key, :value) in counts.entries) '$value× $key',
  ].join(' + ');
}

/// A run's zml-smi samples summed up per device as they arrive.
class ChipAccumulator {
  final Map<int, _Device> _devices = {};
  List<ChipReading> _latest = const [];

  /// The newest sample, for the live readout.
  List<ChipReading> get latest => _latest;

  bool get isEmpty => _devices.isEmpty;

  void add(int tsNs, List<ChipReading> readings) {
    _latest = readings;
    for (final r in readings) {
      (_devices[r.device] ??= _Device(r.kind)).add(tsNs, r);
    }
  }

  /// One summary per device, in device order.
  List<PerfChipStat> stats() => [
    for (final device in _devices.keys.toList()..sort())
      _devices[device]!.stat(device),
  ];

  /// Energy per token: every device's energy over the run divided by
  /// [tokens]. Null without two power readings from some device.
  double? joulesPerToken(int tokens) {
    final energies = [for (final d in _devices.values) ?d.energyJ];
    if (energies.isEmpty || tokens == 0) return null;
    return energies.fold(0.0, (a, b) => a + b) / tokens;
  }
}

class _Device {
  _Device(this.kind);

  final String kind;
  String? name;
  int samples = 0;
  int _utilSum = 0;
  int _utilN = 0;
  int? _utilMax;
  double _powerSum = 0;
  int _powerN = 0;
  double? _powerMax;
  int? _tempMax;
  int? _memPeak;
  int? _memTotal;

  /// Power integrated over the samples (trapezoids between consecutive
  /// power readings); null until there are two.
  double? energyJ;
  int? _lastPowerTs;
  double? _lastPower;

  void add(int tsNs, ChipReading r) {
    samples++;
    name ??= r.name;
    if (r.utilPercent case final u?) {
      _utilSum += u;
      _utilN++;
      _utilMax = math.max(_utilMax ?? u, u);
    }
    if (r.powerW case final p?) {
      _powerSum += p;
      _powerN++;
      _powerMax = math.max(_powerMax ?? p, p);
      if ((_lastPowerTs, _lastPower) case (final t?, final last?)) {
        energyJ = (energyJ ?? 0) + (last + p) / 2 * (tsNs - t) / 1e9;
      }
      _lastPowerTs = tsNs;
      _lastPower = p;
    }
    if (r.temperatureC case final t?) _tempMax = math.max(_tempMax ?? t, t);
    if (r.memUsedBytes case final m?) _memPeak = math.max(_memPeak ?? m, m);
    if (r.memTotalBytes case final m?) _memTotal = math.max(_memTotal ?? m, m);
  }

  PerfChipStat stat(int device) => PerfChipStat(
    device: device,
    kind: kind,
    name: name,
    samples: samples,
    utilAvg: _utilN == 0 ? null : _utilSum / _utilN,
    utilMax: _utilMax,
    powerAvgW: _powerN == 0 ? null : _powerSum / _powerN,
    powerMaxW: _powerMax,
    temperatureMaxC: _tempMax,
    memPeakBytes: _memPeak,
    memTotalBytes: _memTotal,
    energyJ: energyJ,
  );
}
