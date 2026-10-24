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

  /// This device as it's listed in `meta.json`'s `hardware.chips`.
  Map<String, Object> toMeta() => {
    'device': device,
    'kind': kind,
    'name': ?name,
    'driver_version': ?driverVersion,
  };
}
