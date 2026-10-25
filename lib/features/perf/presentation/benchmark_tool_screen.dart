import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collection/collection.dart';

import '../../../core/shell/app_fullscreen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/util/search.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/api_endpoint.dart';
import '../../../models/machine.dart';
import '../../benchmark/presentation/benchmark_view.dart';
import '../../endpoints/application/endpoints_providers.dart';
import '../../machines/application/machines_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../terminal/presentation/terminal_mux.dart';
import '../application/benchmark_target.dart';
import '../application/benchmark_terminal_panel.dart';
import 'chip_metrics_button.dart';
import 'perf_view.dart';

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
  late final TextEditingController _key;

  // Moves the terminal between the split and fullscreen layouts without
  // remounting it (a remount would churn its panes' focus and views).
  final GlobalKey _terminalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final target = ref.read(benchmarkTargetControllerProvider);
    _host = TextEditingController(text: target.hostText);
    _port = TextEditingController(text: target.portText);
    _key = TextEditingController(text: target.customKey);
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _key.dispose();
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
    // The saved custom key arrives from the key store after the first frame.
    ref.listen(benchmarkTargetControllerProvider.select((t) => t.customKey), (
      _,
      key,
    ) {
      if (_key.text != key) _key.text = key;
    });

    final target = ref.watch(benchmarkTargetControllerProvider);
    final fullscreen = ref.watch(appFullscreenProvider);
    final panel = ref.watch(benchmarkTerminalPanelControllerProvider);
    // The target machine's hardware goes on perf recordings.
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
            target: target.chat,
          )
        : PerfView(
            jobId: _adhocJobId,
            jobName: endpoint,
            jobDescription: '',
            jobCommand: '',
            machineName: target.label,
            host: host,
            port: port,
            machine: machine?.name,
            hardware: [
              machine?.gpus,
              machine?.memory,
            ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', '),
          );

    // Mounted only while the panel is open (or animating shut) — the split
    // decides; its shells live on in the mux provider either way.
    final terminal = TerminalMux(key: _terminalKey, muxId: _terminalMuxId);

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
          apiKey: _key,
          selectedMachineId: target.machineId,
          target: target,
          onSelectMachine: _target.selectMachine,
          onSelectEndpoint: _target.selectEndpoint,
          onSelectCustom: _target.selectCustom,
          onHostEdited: _target.setHostText,
          onPortEdited: _target.setPortText,
          onKeyEdited: _target.setCustomKey,
          metricsHost: target.tool == BenchmarkTool.perf && !target.isEndpoint
              ? host
              : null,
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
    required this.target,
    required this.onSelectMachine,
    required this.onSelectEndpoint,
    required this.onSelectCustom,
    required this.onHostEdited,
    required this.onPortEdited,
    required this.apiKey,
    required this.onKeyEdited,
    this.metricsHost,
  });

  final TextEditingController host;
  final TextEditingController port;
  final String? selectedMachineId;
  final BenchmarkTarget target;
  final ValueChanged<Machine> onSelectMachine;
  final ValueChanged<ApiEndpoint> onSelectEndpoint;
  final VoidCallback onSelectCustom;
  final ValueChanged<String> onHostEdited;
  final ValueChanged<String> onPortEdited;

  /// The custom host's key (sent as Bearer when set).
  final TextEditingController apiKey;
  final ValueChanged<String> onKeyEdited;

  /// The host whose chip metrics (zml-smi) the Perf tool records — shows the
  /// Metrics button. Null: no button (the Benchmark tool, an API endpoint).
  final String? metricsHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final machines = ref.watch(machinesStreamProvider).value ?? const [];
    final blurHost = ref.watch(
      settingsControllerProvider.select((s) => s.blurHost),
    );
    final endpoints = ref.watch(endpointsStreamProvider).value ?? const [];
    final onEndpoint = target.isEndpoint;
    final custom = selectedMachineId == null && !onEndpoint;
    final selected = machines.firstWhereOrNull(
      (m) => m.id == selectedMachineId,
    );
    Widget dropdown({double? width}) => _MachineDropdown(
      width: width,
      machines: machines,
      endpoints: endpoints,
      label: onEndpoint ? target.endpointName : selected?.name ?? 'Custom host',
      icon: onEndpoint
          ? AppIcons.web
          : custom
          ? AppIcons.edit
          : AppIcons.machines,
      customSelected: custom,
      selectedMachineId: selectedMachineId,
      selectedEndpointId: target.endpointId,
      onSelectMachine: onSelectMachine,
      onSelectEndpoint: onSelectEndpoint,
      onSelectCustom: onSelectCustom,
      blurHost: blurHost,
    );
    // A saved endpoint: its URL (read-only, edited on the Endpoints screen) and
    // whether a key is in use, instead of host + port.
    final urlText = Text(
      blurHost ? maskHost(target.baseUrl) : target.baseUrl,
      style: context.text.mono.copyWith(color: c.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final keyBadge = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          target.apiKey != null ? AppIcons.check : AppIcons.close,
          size: 12,
          color: target.apiKey != null ? c.statusRunning : c.textFaint,
        ),
        const SizedBox(width: 4),
        Text(
          target.apiKey != null ? 'API key' : 'no key',
          style: context.text.smallMuted,
        ),
      ],
    );
    final hostField = custom
        // Custom: type any host (or a full URL). Still editable while masked —
        // the controller holds the real value either way. The ⋯ holds the
        // API key, rarely needed, so it stays out of the bar.
        ? AppTextField(
            controller: host,
            mono: true,
            dense: true,
            obscureText: blurHost,
            onChanged: onHostEdited,
            suffix: _KeyMenu(
              controller: apiKey,
              hasKey: target.customKey.trim().isNotEmpty,
              onChanged: onKeyEdited,
            ),
          )
        // A machine sets the host; show it read-only.
        : Text(
            blurHost ? maskHost(host.text) : host.text,
            style: context.text.mono.copyWith(color: c.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
    // A custom host may be typed as a full URL (`https://…/v1`); then it
    // carries its own port.
    final showPort = !target.customIsUrl;
    final portField = SizedBox(
      width: 68,
      child: AppTextField(
        controller: port,
        mono: true,
        dense: true,
        onChanged: onPortEdited,
      ),
    );
    Widget label(String text) => Text(text, style: context.text.smallMuted);
    final metrics = [
      if (metricsHost case final host?) ...[
        const SizedBox(width: AppSpacing.md),
        ChipMetricsButton(host: host),
      ],
    ];

    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // One line while the picker keeps ~140 px (the Metrics button
          // takes room too).
          final oneLine = metricsHost != null ? 700.0 : 600.0;
          if (constraints.maxWidth >= oneLine) {
            return Row(
              children: [
                label('Target'),
                const SizedBox(width: AppSpacing.md),
                // The picker takes a real share (it lists machines and
                // endpoints); the address gets the rest, not the whole bar.
                Expanded(flex: 2, child: dropdown()),
                const SizedBox(width: AppSpacing.md),
                Container(width: 1, height: 20, color: c.borderMuted),
                const SizedBox(width: AppSpacing.md),
                if (onEndpoint) ...[
                  label('url'),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 3, child: urlText),
                  const SizedBox(width: AppSpacing.lg),
                  keyBadge,
                ] else ...[
                  label('host'),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 3, child: hostField),
                  if (showPort) ...[
                    const SizedBox(width: AppSpacing.lg),
                    label('port'),
                    const SizedBox(width: AppSpacing.sm),
                    portField,
                  ],
                  ...metrics,
                ],
              ],
            );
          }
          // Too narrow for one line (the terminal is open beside the tools):
          // two rows sharing a label column, so the picker and the host field
          // start at the same x and end with the port field.
          Widget labelled(String text) =>
              SizedBox(width: _labelWidth, child: label(text));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  labelled('Target'),
                  Expanded(child: dropdown()),
                  // Here, not on the host line: that one's full already.
                  ...metrics,
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (onEndpoint)
                Row(
                  children: [
                    labelled('url'),
                    Expanded(child: urlText),
                    const SizedBox(width: AppSpacing.md),
                    keyBadge,
                  ],
                )
              else ...[
                Row(
                  children: [
                    labelled('host'),
                    Expanded(child: hostField),
                    if (showPort) ...[
                      const SizedBox(width: AppSpacing.md),
                      label('port'),
                      const SizedBox(width: AppSpacing.sm),
                      portField,
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// The stacked layout's label column ("Target" is the widest label).
  static const _labelWidth = 52.0;
}

/// The custom host's ⋯ menu: a small popover holding its API key. The button
/// turns into a key when one is set, so it's visible without opening it.
class _KeyMenu extends StatefulWidget {
  const _KeyMenu({
    required this.controller,
    required this.hasKey,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasKey;
  final ValueChanged<String> onChanged;

  @override
  State<_KeyMenu> createState() => _KeyMenuState();
}

class _KeyMenuState extends State<_KeyMenu> {
  final _link = LayerLink();
  final _menu = OverlayPortalController();

  static const _width = 300.0;

  void _toggle() =>
      setState(() => _menu.isShowing ? _menu.hide() : _menu.show());

  void _close() => setState(_menu.hide);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _menu,
        overlayChildBuilder: _buildOverlay,
        child: AppIconButton(
          icon: widget.hasKey ? AppIcons.apiKey : AppIcons.more,
          size: 14,
          padding: const EdgeInsets.all(2),
          color: widget.hasKey ? c.statusRunning : null,
          onPressed: _toggle,
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final c = context.colors;
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
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(4, 8),
          child: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: _width,
              child: AppPanel(
                color: c.surface,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel('API key'),
                    AppTextField(
                      controller: widget.controller,
                      autofocus: true,
                      mono: true,
                      dense: true,
                      obscureText: true,
                      placeholder: 'optional',
                      onChanged: widget.onChanged,
                      onSubmitted: (_) => _close(),
                    ),
                    ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, _) =>
                          widget.controller.text.trim().isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AppButton(
                                  label: 'Remove key',
                                  variant: AppButtonVariant.ghost,
                                  dense: true,
                                  onPressed: () {
                                    widget.controller.clear();
                                    widget.onChanged('');
                                    _close();
                                  },
                                ),
                              ),
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

/// A dropdown button that opens a searchable list of machines (plus a Custom
/// host entry) in an anchored overlay — scales past a handful of machines.
class _MachineDropdown extends StatefulWidget {
  const _MachineDropdown({
    this.width,
    required this.machines,
    required this.endpoints,
    required this.label,
    required this.icon,
    required this.customSelected,
    required this.selectedMachineId,
    required this.selectedEndpointId,
    required this.onSelectMachine,
    required this.onSelectEndpoint,
    required this.onSelectCustom,
    required this.blurHost,
  });

  /// The button's width; null fills what the parent gives it.
  final double? width;
  final List<Machine> machines;
  final List<ApiEndpoint> endpoints;
  final String label;
  final IconData icon;
  final bool customSelected;
  final String? selectedMachineId;
  final String? selectedEndpointId;
  final ValueChanged<Machine> onSelectMachine;
  final ValueChanged<ApiEndpoint> onSelectEndpoint;
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
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hovered ? c.surfaceHover : c.surfaceMuted,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: c.borderMuted),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 12, color: c.textFaint),
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
    final endpoints = q.isEmpty
        ? widget.endpoints
        : widget.endpoints
              .where((e) => matchesSearch(q, [e.name, e.baseUrl]))
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
                      placeholder: 'Search machines and endpoints',
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
                          if (filtered.isEmpty &&
                              endpoints.isEmpty &&
                              q.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Text(
                                'Nothing matches',
                                style: context.text.smallMuted,
                              ),
                            ),
                          // Saved endpoints (managed on the Endpoints screen):
                          // hosted APIs and servers by URL.
                          if (endpoints.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.sm,
                                AppSpacing.sm,
                                AppSpacing.sm,
                                4,
                              ),
                              child: SectionLabel('ENDPOINTS'),
                            ),
                          for (final e in endpoints)
                            _MenuRow(
                              icon: AppIcons.web,
                              title: e.name,
                              subtitle: widget.blurHost
                                  ? maskHost(e.host)
                                  : e.host,
                              selected: e.id == widget.selectedEndpointId,
                              onTap: () {
                                widget.onSelectEndpoint(e);
                                _close();
                              },
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
            Flexible(
              child: Text(
                subtitle,
                style: context.text.monoSmall.copyWith(color: c.textFaint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
