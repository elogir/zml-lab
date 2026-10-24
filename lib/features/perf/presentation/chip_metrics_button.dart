import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/chip_metrics.dart';
import '../domain/run_recorder.dart';

/// The Perf tool's chip metrics, in the target bar: a "Metrics" button whose
/// dot turns green while zml-smi answers for the target, opening a popover
/// with what it found and where it looks — the target's host unless told
/// otherwise.
class ChipMetricsButton extends ConsumerStatefulWidget {
  const ChipMetricsButton({super.key, required this.host});

  /// The benchmark target's host.
  final String host;

  @override
  ConsumerState<ChipMetricsButton> createState() => _ChipMetricsButtonState();
}

class _ChipMetricsButtonState extends ConsumerState<ChipMetricsButton> {
  final _link = LayerLink();
  final _menu = OverlayPortalController();
  late final TextEditingController _field;

  /// The setting as of the last build (probes don't touch `ref`: they can
  /// land while the widget is on its way out).
  late String _setting;

  /// zml-smi's devices at [_url]; null until the first answer (or none).
  List<ChipReading>? _found;
  bool _probing = false;
  String _url = '';
  int _probeSeq = 0;
  Timer? _poll;
  Timer? _debounce;

  static const _width = 340.0;

  /// zml-smi may be started after the tab opens: look again now and then.
  static const _pollEvery = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _setting = ref.read(settingsControllerProvider).perfChipMetricsUrl;
    _field = TextEditingController(text: _setting);
    // Not during initState: probing sets state.
    scheduleMicrotask(_probe);
    _poll = Timer.periodic(_pollEvery, (_) => _probe());
  }

  @override
  void didUpdateWidget(ChipMetricsButton old) {
    super.didUpdateWidget(old);
    if (old.host != widget.host) scheduleMicrotask(_probe);
  }

  String get _host => widget.host.trim();

  @override
  void dispose() {
    _poll?.cancel();
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  Future<void> _probe() async {
    if (!mounted) return;
    final url = zmlSmiUrl(_setting, _host);
    final seq = ++_probeSeq;
    setState(() {
      if (url != _url) _found = null;
      _url = url;
      _probing = true;
    });
    final chips = _host.isEmpty ? const <ChipReading>[] : await fetchChips(url);
    if (!mounted || seq != _probeSeq) return;
    setState(() {
      _found = chips;
      _probing = false;
    });
  }

  /// Typed in the popover; the rebuild it causes probes the new address.
  void _edited(String v) =>
      ref.read(settingsControllerProvider.notifier).setPerfChipMetricsUrl(v);

  void _toggle() {
    setState(() => _menu.isShowing ? _menu.hide() : _menu.show());
    if (_menu.isShowing) _probe();
  }

  void _close() => setState(_menu.hide);

  bool get _answering => _found?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Styled like the target picker beside it.
    final button = HoverRegion(
      onTap: _toggle,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hovered ? c.surfaceHover : c.surfaceMuted,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: c.borderMuted),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.gpu, size: 12, color: c.textFaint),
            const SizedBox(width: 6),
            Text(
              'Metrics',
              style: context.text.small.copyWith(color: c.textSecondary),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: AppDurations.fast,
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _answering ? c.statusRunning : c.borderStrong,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
    final blur = ref.watch(
      settingsControllerProvider.select((s) => s.blurHost),
    );
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.perfChipMetricsUrl),
    );
    if (setting != _setting) {
      _setting = setting;
      // Once typing pauses.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), _probe);
    }
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _menu,
        overlayChildBuilder: (context) => _buildOverlay(context, blur: blur),
        child: button,
      ),
    );
  }

  /// [blur]: hosts are masked (the Settings privacy switch).
  Widget _buildOverlay(BuildContext context, {required bool blur}) {
    final c = context.colors;
    final host = _host;
    String shown(String url) {
      final s = url.replaceFirst(RegExp(r'^http://'), '');
      return blur && host.isNotEmpty
          ? s.replaceAll(host, '•' * host.length)
          : s;
    }

    final found = _found ?? const [];
    final (dot, headline, detail) = switch (_found) {
      _ when host.isEmpty => (
        c.textFaint,
        'No target yet',
        'Pick a machine or a host first.',
      ),
      null => (c.textFaint, 'Looking for zml-smi…', shown(_url)),
      [] => (
        c.textFaint,
        'zml-smi isn\'t answering',
        'Runs are recorded without chip metrics. Start `zml-smi --api` on '
            'the server to add power, utilization and memory.',
      ),
      _ => (
        c.statusRunning,
        describeChips(found),
        'Recorded with every run, from ${shown(_url)}.',
      ),
    };
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
          offset: const Offset(0, 6),
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
                    Text('CHIP METRICS', style: context.text.columnHeader),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            headline,
                            style: context.text.bodyStrong,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_probing && _found != null)
                          Text('checking', style: context.text.smallMuted),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 7 + AppSpacing.sm),
                      child: Text(detail, style: context.text.smallMuted),
                    ),
                    if (found.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      for (final chip in found.take(8))
                        _ChipLine(
                          chip: chip,
                          showName: {for (final f in found) f.name}.length > 1,
                        ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    const FieldLabel('zml-smi address'),
                    AppTextField(
                      controller: _field,
                      mono: true,
                      dense: true,
                      autofocus: !_answering,
                      placeholder: host.isEmpty
                          ? ':$zmlSmiPort'
                          : shown(zmlSmiUrl('', host)),
                      onChanged: _edited,
                      onSubmitted: (_) => _close(),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Empty: the target\'s host on $zmlSmiPort. Or a port, '
                      'host:port or URL.',
                      style: context.text.smallMuted,
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

/// One device in zml-smi's answer, with what it reads right now.
class _ChipLine extends StatelessWidget {
  const _ChipLine({required this.chip, required this.showName});

  final ChipReading chip;

  /// Mixed models: name each line (otherwise the headline already does).
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = [
      if (chip.utilPercent case final u?) '$u%',
      if (chip.powerW case final p?) '${p.round()} W',
      if (chip.temperatureC case final t?) '$t °C',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(left: 7 + AppSpacing.sm, top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '${chip.kind == 'cuda' || chip.kind == 'rocm' ? 'GPU' : chip.kind} '
              '${chip.device}',
              style: context.text.monoSmall,
            ),
          ),
          Expanded(
            child: showName
                ? Text(
                    chip.name ?? chip.kind,
                    style: context.text.small.copyWith(color: c.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(now, style: context.text.monoSmall),
          ),
          if (showName && now.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(now, style: context.text.monoSmall),
          ],
        ],
      ),
    );
  }
}
