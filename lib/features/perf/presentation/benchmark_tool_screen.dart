import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collection/collection.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/search.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/machine.dart';
import '../../benchmark/presentation/benchmark_view.dart';
import '../../job_detail/application/terminal_fullscreen.dart';
import '../../machines/application/machines_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../application/benchmark_target.dart';
import 'perf_view.dart';

/// Bullets in place of an address, when the Blur host setting is on. Matches
/// what a [AppTextField] with `obscureText` shows, so the read-only slot and
/// the editable field look the same while masked.
String maskHost(String host) => '•' * host.trim().length;

/// A stable, job-independent id so the ad-hoc benchmark/perf controllers keep
/// their state (kept alive) across visits and tool switches.
const _adhocJobId = 'adhoc';

/// A standalone tab that points the two benchmarking tools — the chat/throughput
/// grid and the perf load generator — at any endpoint, with no launched job
/// involved. It reuses the exact views from job detail, feeding them a target
/// the user picks here instead of one derived from a job.
class BenchmarkToolScreen extends ConsumerStatefulWidget {
  const BenchmarkToolScreen({super.key});

  @override
  ConsumerState<BenchmarkToolScreen> createState() =>
      _BenchmarkToolScreenState();
}

class _BenchmarkToolScreenState extends ConsumerState<BenchmarkToolScreen> {
  // The target itself lives in a keep-alive provider (it has to survive this
  // screen being rebuilt on every visit); these only mirror its text into the
  // fields, seeded once and written straight back on edit.
  late final TextEditingController _host;
  late final TextEditingController _port;

  @override
  void initState() {
    super.initState();
    final target = ref.read(benchmarkTargetControllerProvider);
    _host = TextEditingController(text: target.hostText);
    _port = TextEditingController(text: target.portText);
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  BenchmarkTargetController get _target =>
      ref.read(benchmarkTargetControllerProvider.notifier);

  void _setTool(BenchmarkTool tool) {
    // The chat grid has no full-window mode; make sure the shell chrome comes
    // back when leaving perf.
    if (tool != BenchmarkTool.perf) {
      ref.read(terminalFullscreenProvider.notifier).exit();
    }
    _target.setTool(tool);
  }

  @override
  Widget build(BuildContext context) {
    // The host can move without the field being touched — picking a machine, or
    // that machine's address being edited on the Machines screen — so mirror it
    // back in. Typing can't be clobbered: every keystroke writes straight
    // through, so the field and the state already agree.
    ref.listen(benchmarkTargetControllerProvider.select((t) => t.hostText), (
      _,
      hostText,
    ) {
      if (_host.text != hostText) _host.text = hostText;
    });

    final target = ref.watch(benchmarkTargetControllerProvider);
    final fullscreen =
        target.tool == BenchmarkTool.perf && ref.watch(terminalFullscreenProvider);
    final host = target.host;
    final port = target.port;
    final endpoint = target.endpoint;

    final body = target.tool == BenchmarkTool.benchmark
        ? BenchmarkView(
            jobId: _adhocJobId,
            jobName: endpoint,
            jobDescription: '',
            jobCommand: '',
            machineName: target.label,
            endpoint: endpoint,
            host: host,
            port: port,
          )
        : PerfView(
            jobId: _adhocJobId,
            jobName: endpoint,
            jobDescription: '',
            jobCommand: '',
            machineName: target.label,
            host: host,
            port: port,
          );

    // In perf fullscreen the shell already hid the sidebar; drop our own
    // chrome too so the run fills the window (the perf view re-adds padding).
    if (fullscreen) return body;

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Benchmark',
            subtitle: 'Point the tools at any endpoint — no job needed.',
            trailing: SegmentedControl<BenchmarkTool>(
              value: target.tool,
              onChanged: _setTool,
              options: const [
                SegmentOption(
                  value: BenchmarkTool.benchmark,
                  label: 'Benchmark',
                  icon: AppIcons.benchmark,
                ),
                SegmentOption(
                  value: BenchmarkTool.perf,
                  label: 'Perf',
                  icon: AppIcons.perf,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _EndpointBar(
            host: _host,
            port: _port,
            selectedMachineId: target.machineId,
            onSelectMachine: _target.selectMachine,
            onSelectCustom: _target.selectCustom,
            onHostEdited: _target.setHostText,
            onPortEdited: _target.setPortText,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Target picker: a searchable machine dropdown (with a Custom-host entry) and
/// the host/port fields. The port is always entered by hand (machines don't
/// carry a server port).
class _EndpointBar extends ConsumerWidget {
  const _EndpointBar({
    required this.host,
    required this.port,
    required this.selectedMachineId,
    required this.onSelectMachine,
    required this.onSelectCustom,
    required this.onHostEdited,
    required this.onPortEdited,
  });

  final TextEditingController host;
  final TextEditingController port;
  final String? selectedMachineId;
  final ValueChanged<Machine> onSelectMachine;
  final VoidCallback onSelectCustom;
  final ValueChanged<String> onHostEdited;
  final ValueChanged<String> onPortEdited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final machines = ref.watch(machinesStreamProvider).value ?? const [];
    final blurHost = ref.watch(
      settingsControllerProvider.select((s) => s.blurHost),
    );
    final custom = selectedMachineId == null;
    final selected = machines.firstWhereOrNull(
      (m) => m.id == selectedMachineId,
    );
    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text('Target', style: context.text.smallMuted),
          const SizedBox(width: AppSpacing.md),
          _MachineDropdown(
            machines: machines,
            label: selected?.name ?? 'Custom host',
            customSelected: custom,
            selectedMachineId: selectedMachineId,
            onSelectMachine: onSelectMachine,
            onSelectCustom: onSelectCustom,
            blurHost: blurHost,
          ),
          const SizedBox(width: AppSpacing.md),
          Container(width: 1, height: 20, color: c.borderMuted),
          const SizedBox(width: AppSpacing.md),
          Text('host', style: context.text.smallMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: custom
                // Custom: type any host. Still editable while masked — the
                // controller holds the real value either way.
                ? AppTextField(
                    controller: host,
                    mono: true,
                    dense: true,
                    obscureText: blurHost,
                    onChanged: onHostEdited,
                  )
                // A machine sets the host; show it read-only.
                : Text(
                    blurHost ? maskHost(host.text) : host.text,
                    style: context.text.mono.copyWith(color: c.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text('port', style: context.text.smallMuted),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 68,
            child: AppTextField(
              controller: port,
              mono: true,
              dense: true,
              onChanged: onPortEdited,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dropdown button that opens a searchable list of machines (plus a Custom
/// host entry) in an anchored overlay — scales past a handful of machines.
class _MachineDropdown extends StatefulWidget {
  const _MachineDropdown({
    required this.machines,
    required this.label,
    required this.customSelected,
    required this.selectedMachineId,
    required this.onSelectMachine,
    required this.onSelectCustom,
    required this.blurHost,
  });

  final List<Machine> machines;
  final String label;
  final bool customSelected;
  final String? selectedMachineId;
  final ValueChanged<Machine> onSelectMachine;
  final VoidCallback onSelectCustom;

  /// Mask the addresses listed under each machine name — leaving them readable
  /// here would undo the masking one click away.
  final bool blurHost;

  @override
  State<_MachineDropdown> createState() => _MachineDropdownState();
}

class _MachineDropdownState extends State<_MachineDropdown> {
  final _link = LayerLink();
  final _menu = OverlayPortalController();
  final _search = TextEditingController();
  String _query = '';

  static const _width = 300.0;

  /// The address shown under a machine's name in the list, masked when the
  /// Blur host setting is on.
  String _addressLabel(Machine m) {
    final address = m.isLocal ? '127.0.0.1' : m.address;
    return widget.blurHost ? maskHost(address) : address;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _query = '');
    _search.clear();
    _menu.show();
  }

  void _close() => _menu.hide();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _menu,
        overlayChildBuilder: _buildOverlay,
        child: HoverRegion(
          onTap: () => _menu.isShowing ? _close() : _open(),
          builder: (context, hovered) => Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hovered ? c.surfaceHover : c.surfaceMuted,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: c.borderMuted),
            ),
            child: Row(
              children: [
                Icon(
                  widget.customSelected ? AppIcons.edit : AppIcons.machines,
                  size: 12,
                  color: c.textFaint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.label,
                    style: context.text.monoSmall.copyWith(
                      color: c.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(AppIcons.chevronDown, size: 13, color: c.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final c = context.colors;
    final q = _query.trim();
    final filtered = q.isEmpty
        ? widget.machines
        : widget.machines
              .where((m) => matchesSearch(q, [m.name, m.address]))
              .toList();
    return Stack(
      children: [
        // Tap outside to dismiss.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: _width,
                maxWidth: _width,
                maxHeight: 360,
              ),
              child: AppPanel(
                color: c.surface,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _search,
                      autofocus: true,
                      prefixIcon: AppIcons.search,
                      placeholder: 'Search machines',
                      dense: true,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MenuRow(
                      icon: AppIcons.edit,
                      title: 'Custom host',
                      subtitle: 'type an address',
                      selected: widget.customSelected,
                      onTap: () {
                        widget.onSelectCustom();
                        _close();
                      },
                    ),
                    if (filtered.isNotEmpty)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: c.borderMuted,
                      ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          for (final m in filtered)
                            _MenuRow(
                              icon: AppIcons.machines,
                              title: m.name,
                              subtitle: _addressLabel(m),
                              selected: m.id == widget.selectedMachineId,
                              onTap: () {
                                widget.onSelectMachine(m);
                                _close();
                              },
                            ),
                          if (filtered.isEmpty && q.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Text(
                                'No matching machines',
                                style: context.text.smallMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One selectable row in the machine dropdown.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: 0.12)
              : (hovered ? c.surfaceHover : null),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: selected ? c.accent : c.textFaint),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: context.text.small.copyWith(
                  color: selected ? c.accent : c.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              subtitle,
              style: context.text.monoSmall.copyWith(color: c.textFaint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
