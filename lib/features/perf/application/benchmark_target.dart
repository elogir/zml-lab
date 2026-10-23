import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/execution/native_io.dart';
import '../../../models/api_endpoint.dart';
import '../../../models/machine.dart';
import '../../../repositories/endpoint_repository.dart';
import '../../endpoints/application/endpoints_providers.dart';
import '../../machines/application/machines_providers.dart';

part 'benchmark_target.g.dart';

/// Which of the two ad-hoc tools the standalone Benchmark tab is showing.
enum BenchmarkTool { benchmark, perf }

/// The endpoint the standalone Benchmark tab points at, plus which tool is
/// selected: a saved machine, a saved endpoint (any URL, maybe with a key),
/// or a typed host. [hostText] / [portText] are the raw field contents so the
/// inputs restore exactly as typed (a half-typed port included); [host] and
/// [port] apply the fallbacks the requests actually use.
class BenchmarkTarget {
  const BenchmarkTarget({
    this.tool = BenchmarkTool.benchmark,
    this.hostText = defaultHost,
    this.portText = '$defaultPort',
    this.machineId,
    this.machineName = defaultHost,
    this.endpointId,
    this.endpointName = '',
    this.baseUrl = '',
    this.apiKey,
  });

  static const defaultHost = '127.0.0.1';
  static const defaultPort = 8000;

  final BenchmarkTool tool;
  final String hostText;
  final String portText;

  /// The selected saved machine, or null.
  final String? machineId;

  /// The picked machine's friendly name (shown in reports). Only meaningful
  /// while [machineId] is set — a custom host labels itself.
  final String machineName;

  /// The selected saved endpoint, or null. Takes precedence over host/port.
  final String? endpointId;
  final String endpointName;
  final String baseUrl;

  /// The endpoint's key, loaded from the Keychain when it's selected.
  final String? apiKey;

  bool get isEndpoint => endpointId != null;

  /// Where requests go.
  ChatEndpoint get chat => isEndpoint
      ? ChatEndpoint(Uri.parse(baseUrl), apiKey: apiKey)
      : ChatEndpoint.hostPort(_typedHost, _typedPort);

  String get _typedHost {
    final h = hostText.trim();
    return h.isEmpty ? defaultHost : h;
  }

  int get _typedPort => int.tryParse(portText.trim()) ?? defaultPort;

  /// Host and port (the perf tool takes only these).
  String get host => isEndpoint ? chat.host : _typedHost;
  int get port => isEndpoint ? chat.port : _typedPort;

  /// How the target reads in the UI and in saved runs/reports.
  String get label => isEndpoint
      ? endpointName
      : machineId != null
      ? machineName
      : _typedHost;
  String get endpoint => isEndpoint ? chat.host : '$label:$port';

  static const _unset = Object();

  BenchmarkTarget copyWith({
    BenchmarkTool? tool,
    String? hostText,
    String? portText,
    Object? machineId = _unset,
    String? machineName,
    Object? endpointId = _unset,
    String? endpointName,
    String? baseUrl,
    Object? apiKey = _unset,
  }) {
    return BenchmarkTarget(
      tool: tool ?? this.tool,
      hostText: hostText ?? this.hostText,
      portText: portText ?? this.portText,
      machineId: identical(machineId, _unset)
          ? this.machineId
          : machineId as String?,
      machineName: machineName ?? this.machineName,
      endpointId: identical(endpointId, _unset)
          ? this.endpointId
          : endpointId as String?,
      endpointName: endpointName ?? this.endpointName,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: identical(apiKey, _unset) ? this.apiKey : apiKey as String?,
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
    // A picked machine or endpoint is a live reference, not a snapshot:
    // editing it elsewhere has to move the target with it.
    ref.listen(machineMapProvider, (_, machines) => _syncMachine(machines));
    ref.listen(endpointMapProvider, (_, map) => _syncEndpoint(map));
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

  /// Follow edits to the selected endpoint; drop it if deleted.
  void _syncEndpoint(Map<String, ApiEndpoint> endpoints) {
    final id = state.endpointId;
    if (id == null) return;
    final e = endpoints[id];
    if (e == null) {
      state = state.copyWith(endpointId: null, apiKey: null);
      return;
    }
    if (e.name != state.endpointName || e.baseUrl != state.baseUrl) {
      state = state.copyWith(endpointName: e.name, baseUrl: e.baseUrl);
    }
  }

  void setTool(BenchmarkTool tool) => state = state.copyWith(tool: tool);

  /// Point at a saved machine: its address becomes the host, its name the label.
  void selectMachine(Machine m) => state = state.copyWith(
    machineId: m.id,
    machineName: m.name,
    hostText: m.isLocal ? BenchmarkTarget.defaultHost : m.address,
    endpointId: null,
    apiKey: null,
  );

  /// Point at a saved endpoint and load its key.
  Future<void> selectEndpoint(ApiEndpoint e) async {
    state = state.copyWith(
      endpointId: e.id,
      endpointName: e.name,
      baseUrl: e.baseUrl,
      machineId: null,
      apiKey: null,
    );
    await reloadKey(e.id);
  }

  /// Re-read [endpointId]'s key (after it was edited), if it's selected.
  Future<void> reloadKey(String endpointId) async {
    final key = await ref.read(apiKeyStoreProvider).read(endpointId);
    if (state.endpointId == endpointId) state = state.copyWith(apiKey: key);
  }

  /// Switch to a hand-typed host (deselects any machine or endpoint, keeps
  /// the address).
  void selectCustom() =>
      state = state.copyWith(machineId: null, endpointId: null, apiKey: null);

  void setHostText(String value) => state = state.copyWith(hostText: value);

  void setPortText(String value) => state = state.copyWith(portText: value);
}
