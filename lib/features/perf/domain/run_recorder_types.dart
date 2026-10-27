import 'csv_events.dart';

/// A run file's name ends with this (docs/perf-run-format.md).
const runFileExtension = '.jsonl.gz';

/// The `schema_version` of the run files ZML-Lab writes.
const runSchemaVersion = 1;

/// A run file's rows in the order they were recorded: the streamed chunks,
/// and each zml-smi reading with when it was taken.
class RunRows {
  const RunRows({required this.events, required this.chips});

  final List<PerfEvent> events;
  final List<(int tsNs, ChipReading reading)> chips;
}

/// One device in a zml-smi sample (a row of the run's `chip` table).
class ChipReading {
  const ChipReading({
    required this.device,
    required this.kind,
    this.name,
    this.driverVersion,
    this.utilPercent,
    this.powerW,
    this.powerLimitW,
    this.temperatureC,
    this.memUsedBytes,
    this.memTotalBytes,
    this.clockGraphicsMhz,
    this.clockMemMhz,
    this.pcieTxKbps,
    this.pcieRxKbps,
  });

  final int device;

  /// `cuda`, `rocm`, `oneapi`, `neuron` or `tpu`.
  final String kind;
  final String? name;
  final String? driverVersion;
  final int? utilPercent;
  final double? powerW;
  final double? powerLimitW;
  final int? temperatureC;
  final int? memUsedBytes;
  final int? memTotalBytes;
  final int? clockGraphicsMhz;
  final int? clockMemMhz;
  final int? pcieTxKbps;
  final int? pcieRxKbps;

  /// The devices in a `zml-smi --api` response
  /// (`{devices: [{<kind>: {...}}, ...], processes: [...]}`).
  static List<ChipReading> parse(Object? json) {
    final devices = json is Map ? json['devices'] : null;
    if (devices is! List) return const [];
    final out = <ChipReading>[];
    for (var i = 0; i < devices.length; i++) {
      final entry = devices[i];
      if (entry is! Map || entry.length != 1) continue;
      final kind = '${entry.keys.first}';
      final m = entry.values.first;
      if (m is! Map) continue;
      int? n(String k) => switch (m[k]) {
        final num v => v.toInt(),
        _ => null,
      };
      double? watts(String k) => switch (m[k]) {
        final num v => v / 1000,
        _ => null,
      };
      out.add(
        ChipReading(
          device: i,
          kind: kind,
          name: m['name'] as String?,
          driverVersion: m['driver_version'] as String?,
          utilPercent: n('util_percent'),
          powerW: watts('power_mw'),
          powerLimitW: watts('power_limit_mw'),
          temperatureC: n('temperature'),
          memUsedBytes: n('mem_used_bytes'),
          memTotalBytes: n('mem_total_bytes'),
          clockGraphicsMhz: n('clock_graphics_mhz'),
          clockMemMhz: n('clock_mem_mhz'),
          pcieTxKbps: n('pcie_tx_kbps'),
          pcieRxKbps: n('pcie_rx_kbps'),
        ),
      );
    }
    return out;
  }

  /// This reading as a run file's `chip` line, taken at [tUs]; metrics the
  /// device doesn't report are left out.
  Map<String, Object> toRunLine(int tUs) => {
    'type': 'chip',
    't_us': tUs,
    'device': device,
    'kind': kind,
    'name': ?name,
    'util_percent': ?utilPercent,
    'power_w': ?powerW,
    'power_limit_w': ?powerLimitW,
    'temperature_c': ?temperatureC,
    'mem_used_bytes': ?memUsedBytes,
    'mem_total_bytes': ?memTotalBytes,
    'clock_graphics_mhz': ?clockGraphicsMhz,
    'clock_mem_mhz': ?clockMemMhz,
    'pcie_tx_kbps': ?pcieTxKbps,
    'pcie_rx_kbps': ?pcieRxKbps,
  };

  /// A run file's `chip` line.
  factory ChipReading.fromRunLine(Map<String, Object?> line) {
    int? n(String k) => (line[k] as num?)?.toInt();
    return ChipReading(
      device: n('device') ?? 0,
      kind: line['kind'] as String? ?? '',
      name: line['name'] as String?,
      utilPercent: n('util_percent'),
      powerW: (line['power_w'] as num?)?.toDouble(),
      powerLimitW: (line['power_limit_w'] as num?)?.toDouble(),
      temperatureC: n('temperature_c'),
      memUsedBytes: n('mem_used_bytes'),
      memTotalBytes: n('mem_total_bytes'),
      clockGraphicsMhz: n('clock_graphics_mhz'),
      clockMemMhz: n('clock_mem_mhz'),
      pcieTxKbps: n('pcie_tx_kbps'),
      pcieRxKbps: n('pcie_rx_kbps'),
    );
  }

  /// This device as it's listed in `meta.json`'s `hardware.chips`.
  Map<String, Object> toMeta() => {
    'device': device,
    'kind': kind,
    'name': ?name,
    'driver_version': ?driverVersion,
  };
}
