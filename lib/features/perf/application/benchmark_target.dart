import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/machine.dart';
import '../../machines/application/machines_providers.dart';

part 'benchmark_target.g.dart';

/// Which of the two ad-hoc tools the standalone Benchmark tab is showing.
enum BenchmarkTool { benchmark, perf }

/// The endpoint the standalone Benchmark tab points at, plus which tool is
/// selected. [hostText] / [portText] are the raw field contents so the inputs
/// restore exactly as typed (a half-typed port included); [host] and [port]
/// apply the fallbacks the requests actually use.
class BenchmarkTarget {
  const BenchmarkTarget({
    this.tool = BenchmarkTool.benchmark,
    this.hostText = defaultHost,
    this.portText = '$defaultPort',
    this.machineId,
    this.machineName = defaultHost,
  });

  static const defaultHost = '127.0.0.1';
  static const defaultPort = 8000;

  final BenchmarkTool tool;
  final String hostText;
  final String portText;

  /// The selected saved machine, or null for a hand-typed host.
  final String? machineId;

  /// The picked machine's friendly name (shown in reports). Only meaningful
  /// while [machineId] is set — a custom host labels itself.
  final String machineName;

  String get host {
    final h = hostText.trim();
    return h.isEmpty ? defaultHost : h;
  }

  int get port => int.tryParse(portText.trim()) ?? defaultPort;

  /// How the target reads in the UI and in saved runs/reports.
  String get label => machineId != null ? machineName : host;
  String get endpoint => '$label:$port';

  static const _unset = Object();

  BenchmarkTarget copyWith({
    BenchmarkTool? tool,
    String? hostText,
    String? portText,
    Object? machineId = _unset,
    String? machineName,
  }) {
    return BenchmarkTarget(
      tool: tool ?? this.tool,
      hostText: hostText ?? this.hostText,
      portText: portText ?? this.portText,
      machineId:
          identical(machineId, _unset) ? this.machineId : machineId as String?,
      machineName: machineName ?? this.machineName,
    );
  }
}

/// Holds the ad-hoc Benchmark tab's target. Keep-alive because the screen is
/// built from scratch on every visit — kept in the widget's State, the target
/// snapped back to 127.0.0.1:8000 (and to the Benchmark tool) each time you
/// navigated away and back, while the run itself survived under the `adhoc`
/// job id.
@Riverpod(keepAlive: true)
class BenchmarkTargetController extends _$BenchmarkTargetController {
  @override
  BenchmarkTarget build() {
    // A picked machine is a live reference, not a snapshot: editing its address
    // (or name) on the Machines screen has to move the target with it. Without
    // this the tab kept whatever the address was at selection time until the
    // app restarted or you re-picked the machine.
    ref.listen(machineMapProvider, (_, machines) => _syncMachine(machines));
    return const BenchmarkTarget();
  }

  /// Re-read the selected machine's address/name after any machine edit.
  void _syncMachine(Map<String, Machine> machines) {
    final id = state.machineId;
    if (id == null) return;
    final m = machines[id];
    // Deleted out from under us — keep the address, drop to a custom host.
    if (m == null) {
      state = state.copyWith(machineId: null);
      return;
    }
    final host = m.isLocal ? BenchmarkTarget.defaultHost : m.address;
    if (host == state.hostText && m.name == state.machineName) return;
    state = state.copyWith(hostText: host, machineName: m.name);
  }

  void setTool(BenchmarkTool tool) => state = state.copyWith(tool: tool);

  /// Point at a saved machine: its address becomes the host, its name the label.
  void selectMachine(Machine m) => state = state.copyWith(
    machineId: m.id,
    machineName: m.name,
    hostText: m.isLocal ? BenchmarkTarget.defaultHost : m.address,
  );

  /// Switch to a hand-typed host (deselects any machine, keeps the address).
  void selectCustom() => state = state.copyWith(machineId: null);

  void setHostText(String value) => state = state.copyWith(hostText: value);

  void setPortText(String value) => state = state.copyWith(portText: value);
}
