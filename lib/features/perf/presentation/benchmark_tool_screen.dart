import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collection/collection.dart';

import '../../../core/shell/app_fullscreen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/search.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/machine.dart';
import '../../benchmark/presentation/benchmark_view.dart';
import '../../machines/application/machines_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../terminal/presentation/terminal_mux.dart';
import '../application/benchmark_target.dart';
import '../application/benchmark_terminal_panel.dart';
import 'perf_view.dart';

/// Bullets in place of an address, when the Blur host setting is on. Matches
/// what a [AppTextField] with `obscureText` shows, so the read-only slot and
/// the editable field look the same while masked.
String maskHost(String host) => '•' * host.trim().length;

/// A stable id so the benchmark/perf controllers keep their state (kept alive)
/// across visits and tool switches.
const _adhocJobId = 'adhoc';

/// The terminal multiplexer beside the tools (its shells persist across visits).
const _terminalMuxId = 'benchmark';

/// The home tab: points the two benchmarking tools — the chat/throughput grid
/// and the perf load generator — at any endpoint, beside a terminal
/// multiplexer for launching and watching the server being measured.
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

  // Moves the terminal between the split and fullscreen layouts without
  // remounting it (a remount would churn its panes' focus and views).
  final GlobalKey _terminalKey = GlobalKey();

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
      ref.read(appFullscreenProvider.notifier).exitIf(FullscreenSurface.perf);
    }
    _target.setTool(tool);
  }

  void _toggleTerminal() {
    ref.read(appFullscreenProvider.notifier).exitIf(FullscreenSurface.terminal);
    ref.read(benchmarkTerminalPanelControllerProvider.notifier).toggle();
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
    final fullscreen = ref.watch(appFullscreenProvider);
    final panel = ref.watch(benchmarkTerminalPanelControllerProvider);
    // New shells open on the target machine (ssh when it's remote); a custom
    // host gets local shells.
    final machine = target.machineId == null
        ? null
        : ref.watch(machineMapProvider)[target.machineId];
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

    // Mounted only while the panel is open (or animating shut) — the split
    // decides; its shells live on in the mux provider either way.
    final terminal = TerminalMux(
      key: _terminalKey,
      muxId: _terminalMuxId,
      machine: machine,
    );

    // In fullscreen the shell already hid the sidebar; drop our own chrome too
    // so the surface fills the window (the perf view re-adds padding).
    if (fullscreen == FullscreenSurface.perf &&
        target.tool == BenchmarkTool.perf) {
      return body;
    }
    if (fullscreen == FullscreenSurface.terminal && panel.open) {
      return terminal;
    }

    final tools = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    );

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Benchmark',
            subtitle: 'Launch a server in the terminal, point the tools at it.',
            trailing: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedControl<BenchmarkTool>(
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
                  const SizedBox(width: AppSpacing.sm),
                  AppToggleIconButton(
                    icon: AppIcons.terminal,
                    value: panel.open,
                    onChanged: (_) => _toggleTerminal(),
                    semanticLabel: 'Terminal panel',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _TerminalSplit(
              open: panel.open,
              ratio: panel.ratio,
              onRatioChanged: ref
                  .read(benchmarkTerminalPanelControllerProvider.notifier)
                  .setRatio,
              tools: tools,
              terminal: terminal,
            ),
          ),
        ],
      ),
    );
  }
}

/// The tools on the left, the terminal on the right, with a draggable gutter
/// between them. [ratio] is the terminal's share of the width. Toggling
/// [open] slides the terminal in from / out to the right edge.
class _TerminalSplit extends StatefulWidget {
  const _TerminalSplit({
    required this.open,
    required this.ratio,
    required this.onRatioChanged,
    required this.tools,
    required this.terminal,
  });

  final bool open;
  final double ratio;
  final ValueChanged<double> onRatioChanged;
  final Widget tools;
  final Widget terminal;

  @override
  State<_TerminalSplit> createState() => _TerminalSplitState();
}

class _TerminalSplitState extends State<_TerminalSplit>
    with SingleTickerProviderStateMixin {
  static const _gutter = AppSpacing.lg;
  static const _minTools = 340.0;
  static const _minTerminal = 280.0;

  // The drag is measured from where it started, not accumulated from deltas:
  // several pointer moves land per frame, and adding each to the last *built*
  // ratio dropped all but one, so the divider lagged behind the cursor (and
  // drifted off it after hitting a clamp).
  double _dragStartX = 0;
  double _dragStartRatio = 0;

  /// 1 = open, 0 = shut; drives the slide.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: widget.open ? 1 : 0,
  );
  late final Animation<double> _slide = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(_TerminalSplit old) {
    super.didUpdateWidget(old);
    if (widget.open != old.open) {
      widget.open ? _reveal.forward() : _reveal.reverse();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Row keeps the same shape at every step (the terminal slot just has
    // zero width when shut), so the tools are never remounted by a toggle.
    return AnimatedBuilder(
      animation: _slide,
      builder: (context, _) => _buildSplit(context, _slide.value),
    );
  }

  Widget _buildSplit(BuildContext context, double t) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = (constraints.maxWidth - _gutter).clamp(
          0.0,
          double.infinity,
        );
        // Pixel floors on both sides (the tools' controls overflow below
        // ~320px), relaxed when the window can't fit both.
        final maxTerminal = math.max(0.0, usable - _minTools);
        final minTerminal = math.min(_minTerminal, maxTerminal);
        final terminalWidth = (usable * widget.ratio).clamp(
          minTerminal,
          maxTerminal,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.tools),
            if (t == 0)
              const SizedBox.shrink()
            else
              SizedBox(
                width: _gutter * t,
                child: ClipRect(
                  clipBehavior: t < 1 ? Clip.hardEdge : Clip.none,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: _gutter,
                    maxWidth: _gutter,
                    child: _gutterHandle(
                      c,
                      usable,
                      terminalWidth,
                      minTerminal,
                      maxTerminal,
                    ),
                  ),
                ),
              ),
            if (t == 0)
              const SizedBox.shrink()
            else
              // Laid out at its full width while it slides, so the terminal
              // doesn't re-wrap (and resize the PTY) on every frame. Clipped
              // only mid-slide: a settled panel may hold web tabs, and native
              // web views don't belong under a clip.
              SizedBox(
                width: terminalWidth * t,
                child: ClipRect(
                  clipBehavior: t < 1 ? Clip.hardEdge : Clip.none,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: terminalWidth,
                    maxWidth: terminalWidth,
                    child: widget.terminal,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _gutterHandle(
    AppColors c,
    double usable,
    double terminalWidth,
    double minTerminal,
    double maxTerminal,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (d) {
          _dragStartX = d.globalPosition.dx;
          // What's on screen, not the stored ratio: they differ while
          // a floor holds, and starting from the stored one would
          // leave a dead zone before the divider moved.
          _dragStartRatio = usable > 0 ? terminalWidth / usable : widget.ratio;
        },
        onHorizontalDragUpdate: (d) {
          if (usable <= 0) return;
          final dx = d.globalPosition.dx - _dragStartX;
          final width = (usable * _dragStartRatio - dx).clamp(
            minTerminal,
            maxTerminal,
          );
          widget.onRatioChanged(width / usable);
        },
        child: SizedBox(
          width: _gutter,
          child: Center(
            child: Container(
              width: 2,
              height: 32,
              decoration: BoxDecoration(
                color: c.borderMuted,
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
        ),
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
    final picker = [
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
    ];
    final address = [
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
    ];
    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      // Stack the picker over the address when the terminal leaves the tools
      // too narrow for one line.
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 460
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: picker),
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: address),
                ],
              )
            : Row(
                children: [
                  ...picker,
                  const SizedBox(width: AppSpacing.md),
                  Container(width: 1, height: 20, color: c.borderMuted),
                  const SizedBox(width: AppSpacing.md),
                  ...address,
                ],
              ),
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
