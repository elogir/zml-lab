import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/perf_report.dart';
import '../../../models/settings.dart';
import '../../perf/domain/bench_runner.dart';
import '../../updates/application/updater.dart';
import '../../updates/domain/update_release.dart';
import '../application/settings_controller.dart';
import 'copy_template_editor.dart';

/// App-wide preferences, grouped into panels. Every control writes through to
/// the settings store immediately — there is no save button.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _prompt;
  late final TextEditingController _batch;
  late final TextEditingController _maxTokens;
  late final TextEditingController _temperature;
  late final TextEditingController _benchModel;
  late final TextEditingController _copyTemplate;
  late final TextEditingController _perfDataset;
  late final TextEditingController _perfZmlSmiPort;
  late final TextEditingController _perfDuration;
  late final TextEditingController _perfConcurrency;
  late final TextEditingController _perfMaxTokens;
  late final TextEditingController _perfModel;

  SettingsController get _controller =>
      ref.read(settingsControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsControllerProvider);
    _prompt = TextEditingController(text: s.benchPrompt);
    _batch = TextEditingController(text: '${s.benchBatchSize}');
    _maxTokens = TextEditingController(
      text: s.benchMaxTokens?.toString() ?? '',
    );
    _temperature = TextEditingController(
      text: s.benchTemperature?.toString() ?? '',
    );
    _benchModel = TextEditingController(text: s.benchModel);
    _copyTemplate = TextEditingController(text: s.benchCopyTemplate);
    _perfDataset = TextEditingController(text: s.perfDatasetPath);
    _perfZmlSmiPort = TextEditingController(
      text: s.perfZmlSmiPort == defaultZmlSmiPort ? '' : '${s.perfZmlSmiPort}',
    );
    _perfDuration = TextEditingController(
      text: '${s.perfParams.durationSeconds}',
    );
    _perfConcurrency = TextEditingController(
      text: '${s.perfParams.concurrency}',
    );
    _perfMaxTokens = TextEditingController(
      text: s.perfParams.maxCompletionTokens?.toString() ?? '',
    );
    _perfModel = TextEditingController(text: s.perfParams.model);
  }

  @override
  void dispose() {
    _prompt.dispose();
    _batch.dispose();
    _maxTokens.dispose();
    _temperature.dispose();
    _benchModel.dispose();
    _copyTemplate.dispose();
    _perfDataset.dispose();
    _perfZmlSmiPort.dispose();
    _perfDuration.dispose();
    _perfConcurrency.dispose();
    _perfMaxTokens.dispose();
    _perfModel.dispose();
    super.dispose();
  }

  /// Edits the shared perf-run params (the Perf tab's form reads the same
  /// blob, so a change here shows up there while idle).
  void _patchPerf(PerfParams Function(PerfParams) patch) {
    _controller.setPerfParams(
      patch(ref.read(settingsControllerProvider).perfParams),
    );
  }

  Future<void> _reset() async {
    await ref.read(settingsControllerProvider.notifier).resetAll();
    if (!mounted) return;
    // Mirror the fresh defaults back into the (uncontrolled) fields.
    final s = ref.read(settingsControllerProvider);
    setState(() {
      _prompt.text = s.benchPrompt;
      _batch.text = '${s.benchBatchSize}';
      _maxTokens.text = '';
      _temperature.text = '';
      _benchModel.text = '';
      _copyTemplate.text = s.benchCopyTemplate;
      _perfDataset.text = s.perfDatasetPath;
      _perfZmlSmiPort.text = '';
      _perfDuration.text = '${s.perfParams.durationSeconds}';
      _perfConcurrency.text = '${s.perfParams.concurrency}';
      _perfMaxTokens.text = '';
      _perfModel.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsControllerProvider);

    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(
                title: 'Settings',
                subtitle: 'App-wide preferences. Changes apply immediately.',
              ),
              const SizedBox(height: AppSpacing.xl),

              _Group(
                label: 'Appearance',
                children: [
                  _SettingRow(
                    title: 'Theme',
                    description: 'Follow the system, or force a palette.',
                    control: SegmentedControl<AppThemeMode>(
                      value: s.themeMode,
                      onChanged: _controller.setThemeMode,
                      options: const [
                        SegmentOption(
                          value: AppThemeMode.system,
                          label: 'System',
                          icon: AppIcons.themeSystem,
                        ),
                        SegmentOption(
                          value: AppThemeMode.light,
                          label: 'Light',
                          icon: AppIcons.themeLight,
                        ),
                        SegmentOption(
                          value: AppThemeMode.dark,
                          label: 'Dark',
                          icon: AppIcons.themeDark,
                        ),
                      ],
                    ),
                  ),
                  _SettingRow(
                    title: 'Blur host',
                    description:
                        'Mask the address in the Benchmark tab\'s target bar, '
                        'for screenshots and screen-sharing. Requests still '
                        'go to the real host.',
                    control: SegmentedControl<bool>(
                      value: s.blurHost,
                      onChanged: _controller.setBlurHost,
                      options: const [
                        SegmentOption(value: true, label: 'On'),
                        SegmentOption(value: false, label: 'Off'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _Group(
                label: 'Terminal',
                children: [
                  _SettingRow(
                    title: 'Font size',
                    description: 'Applies to open terminals right away.',
                    control: _Stepper(
                      value: '${s.terminalFontSize.round()} px',
                      onDecrement:
                          s.terminalFontSize > SettingsLimits.minTerminalFont
                          ? () => _controller.setTerminalFontSize(
                              s.terminalFontSize - 1,
                            )
                          : null,
                      onIncrement:
                          s.terminalFontSize < SettingsLimits.maxTerminalFont
                          ? () => _controller.setTerminalFontSize(
                              s.terminalFontSize + 1,
                            )
                          : null,
                    ),
                  ),
                  _SettingRow(
                    title: 'Option as Meta',
                    description:
                        'Option+letter sends ESC+letter so Option+F/B jump '
                        'words in the shell.',
                    control: SegmentedControl<bool>(
                      value: s.terminalOptionAsMeta,
                      onChanged: _controller.setTerminalOptionAsMeta,
                      options: const [
                        SegmentOption(value: true, label: 'On'),
                        SegmentOption(value: false, label: 'Off'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _Group(
                label: 'Benchmark defaults',
                children: [
                  _SettingRow(
                    title: 'Prompt',
                    description:
                        'What a fresh benchmark run starts with. A run already '
                        'open keeps its own prompt.',
                    stacked: true,
                    control: AppTextField(
                      controller: _prompt,
                      mono: true,
                      minLines: 2,
                      maxLines: 4,
                      onChanged: _controller.setBenchPrompt,
                    ),
                  ),
                  _SettingRow(
                    title: 'Batch size',
                    description: 'Concurrent requests per run.',
                    control: SizedBox(
                      width: 64,
                      child: AppTextField(
                        controller: _batch,
                        mono: true,
                        onChanged: (v) {
                          final n = int.tryParse(v.trim());
                          if (n != null) _controller.setBenchBatchSize(n);
                        },
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'Max output tokens',
                    description:
                        'Empty = unlimited: the server stops at EOS or its '
                        'max sequence length.',
                    control: SizedBox(
                      width: 76,
                      child: AppTextField(
                        controller: _maxTokens,
                        mono: true,
                        placeholder: '∞',
                        onChanged: (v) => _controller.setBenchMaxTokens(
                          int.tryParse(v.trim()),
                        ),
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'Temperature',
                    description: 'Empty = the server\'s default sampling.',
                    control: SizedBox(
                      width: 76,
                      child: AppTextField(
                        controller: _temperature,
                        mono: true,
                        placeholder: 'auto',
                        onChanged: (v) => _controller.setBenchTemperature(
                          double.tryParse(v.trim()),
                        ),
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'Model',
                    description:
                        'Sent with each request. vLLM needs the real name; '
                        'llmd ignores it. Empty = the server\'s model, when '
                        '/v1/models lists just one (else zml_model).',
                    stacked: true,
                    control: AppTextField(
                      controller: _benchModel,
                      mono: true,
                      placeholder: 'from /v1/models',
                      onChanged: _controller.setBenchModel,
                    ),
                  ),
                  _SettingRow(
                    title: 'Ignore EOS',
                    description:
                        'Every reply runs to the max output tokens, so runs '
                        'compare like for like. Sends ignore_eos (llmd, vLLM, '
                        'SGLang).',
                    control: SegmentedControl<bool>(
                      value: s.benchIgnoreEos,
                      onChanged: _controller.setBenchIgnoreEos,
                      options: const [
                        SegmentOption(value: true, label: 'On'),
                        SegmentOption(value: false, label: 'Off'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _Group(
                label: 'Copy results',
                children: [
                  _SettingRow(
                    title: 'Format',
                    description:
                        'What "Copy results" puts on the clipboard after a '
                        'run (live or saved). Placeholders are filled from '
                        'the run; empty restores the default.',
                    stacked: true,
                    control: CopyTemplateEditor(
                      controller: _copyTemplate,
                      onChanged: _controller.setBenchCopyTemplate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _Group(
                label: 'Perf benchmark',
                children: [
                  _SettingRow(
                    title: 'ShareGPT dataset',
                    description:
                        'The conversations the benchmarker draws prompts '
                        'from. The Perf tab downloads it here when missing.',
                    stacked: true,
                    control: FieldWithActions(
                      field: AppTextField(
                        controller: _perfDataset,
                        mono: true,
                        placeholder: defaultPerfDatasetPath,
                        onChanged: _controller.setPerfDatasetPath,
                      ),
                      // To find it — and delete or move it — in Finder.
                      actions: ({required stretch}) => AppButton(
                        label: 'Show in Finder',
                        icon: AppIcons.folder,
                        fill: stretch,
                        onPressed: () =>
                            revealInFinder(expandUserPath(s.perfDatasetPath)),
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'zml-smi port',
                    description:
                        'Where Metrics looks for zml-smi --api on the '
                        'target\'s host, for power, utilization and memory '
                        'during runs. The Metrics popover can point '
                        'elsewhere.',
                    control: SizedBox(
                      width: 72,
                      child: AppTextField(
                        controller: _perfZmlSmiPort,
                        mono: true,
                        placeholder: '$defaultZmlSmiPort',
                        onChanged: (v) => _controller.setPerfZmlSmiPort(
                          int.tryParse(v.trim()),
                        ),
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'Duration',
                    description:
                        'How long each run generates load, in seconds.',
                    control: SizedBox(
                      width: 72,
                      child: AppTextField(
                        controller: _perfDuration,
                        mono: true,
                        onChanged: (v) {
                          final n = int.tryParse(v.trim());
                          if (n != null && n > 0) {
                            _patchPerf((p) => p.copyWith(durationSeconds: n));
                          }
                        },
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'Concurrency',
                    description:
                        'Requests kept in flight — match it to the server\'s '
                        'batch size.',
                    control: SizedBox(
                      width: 72,
                      child: AppTextField(
                        controller: _perfConcurrency,
                        mono: true,
                        onChanged: (v) {
                          final n = int.tryParse(v.trim());
                          if (n != null && n > 0) {
                            _patchPerf((p) => p.copyWith(concurrency: n));
                          }
                        },
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'Max output tokens',
                    description:
                        'Per request. Empty = no cap: the server stops at '
                        'EOS or its max sequence length.',
                    control: SizedBox(
                      width: 96,
                      child: AppTextField(
                        controller: _perfMaxTokens,
                        mono: true,
                        placeholder: '∞',
                        onChanged: (v) {
                          final n = int.tryParse(v.trim());
                          _patchPerf(
                            (p) => p.copyWith(
                              maxCompletionTokens: n != null && n > 0
                                  ? n
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'Prompt length',
                    description:
                        'Long sends the whole prompt; short caps it at 512 '
                        'characters.',
                    control: SegmentedControl<String>(
                      value: s.perfParams.sequenceType,
                      onChanged: (v) =>
                          _patchPerf((p) => p.copyWith(sequenceType: v)),
                      options: const [
                        SegmentOption(value: 'long', label: 'Long'),
                        SegmentOption(value: 'short', label: 'Short'),
                      ],
                    ),
                  ),
                  _SettingRow(
                    title: 'Turns',
                    description:
                        'All uses every turn of a conversation; first only its '
                        'opening prompt (prefix-caching test).',
                    control: SegmentedControl<String>(
                      value: s.perfParams.mode,
                      onChanged: (v) => _patchPerf((p) => p.copyWith(mode: v)),
                      options: const [
                        SegmentOption(value: 'all', label: 'All'),
                        SegmentOption(value: 'first', label: 'First'),
                      ],
                    ),
                  ),
                  _SettingRow(
                    title: 'Warm-up',
                    description:
                        'Before measuring, run prefill, decode and mixed '
                        'batches at the run\'s concurrency (kernels compiled '
                        'just in time get compiled), then start the run '
                        'with no idle gap, so the GPU clocks stay up.',
                    control: SegmentedControl<bool>(
                      value: s.perfParams.warmup,
                      onChanged: (v) =>
                          _patchPerf((p) => p.copyWith(warmup: v)),
                      options: const [
                        SegmentOption(value: true, label: 'On'),
                        SegmentOption(value: false, label: 'Off'),
                      ],
                    ),
                  ),
                  _SettingRow(
                    title: 'Ignore EOS',
                    description:
                        'Every reply runs to the max output tokens, so runs '
                        'compare like for like. Sends ignore_eos (llmd, vLLM, '
                        'SGLang).',
                    control: SegmentedControl<bool>(
                      value: s.perfParams.ignoreEos,
                      onChanged: (v) =>
                          _patchPerf((p) => p.copyWith(ignoreEos: v)),
                      options: const [
                        SegmentOption(value: true, label: 'On'),
                        SegmentOption(value: false, label: 'Off'),
                      ],
                    ),
                  ),
                  _SettingRow(
                    title: 'Model',
                    description:
                        'Sent in each request. vLLM needs the real name; llmd '
                        'ignores it. Empty = the server\'s model, when '
                        '/v1/models lists just one.',
                    stacked: true,
                    control: AppTextField(
                      controller: _perfModel,
                      mono: true,
                      placeholder: 'from /v1/models',
                      onChanged: (v) =>
                          _patchPerf((p) => p.copyWith(model: v.trim())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _Group(
                label: 'Updates',
                children: [
                  _SettingRow(
                    title: 'Auto update',
                    description:
                        'On: new releases from GitHub download in the '
                        'background and install when you quit (or sooner, '
                        'from Restart to update in the sidebar). Off: the '
                        'sidebar shows Update to …, and nothing downloads '
                        'until you click it.',
                    control: SegmentedControl<bool>(
                      value: s.autoUpdate,
                      onChanged: _controller.setAutoUpdate,
                      options: const [
                        SegmentOption(value: true, label: 'On'),
                        SegmentOption(value: false, label: 'Off'),
                      ],
                    ),
                  ),
                  const _UpdateStatusRow(),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Restore every setting to its built-in default.',
                      style: context.text.smallMuted,
                    ),
                  ),
                  AppButton(
                    label: 'Reset to defaults',
                    icon: AppIcons.restart,
                    onPressed: _reset,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// This build's version and where updating stands, with "Check now".
class _UpdateStatusRow extends ConsumerWidget {
  const _UpdateStatusRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updaterProvider);
    final autoUpdate = ref.watch(
      settingsControllerProvider.select((s) => s.autoUpdate),
    );
    final checked = status.checkedAt == null
        ? 'Not checked yet.'
        : 'Last checked at ${_clock(status.checkedAt!)}.';
    final description = switch (status.phase) {
      UpdatePhase.unavailable =>
        'A local build: only release builds update themselves.',
      UpdatePhase.idle => 'Up to date. $checked',
      UpdatePhase.checking => 'Checking GitHub…',
      UpdatePhase.available => switch (status.error) {
        null =>
          '${status.version} is out: Update to ${status.version} in the '
              'sidebar downloads and installs it.',
        final error =>
          '$error Update to ${status.version} in the sidebar tries again.',
      },
      UpdatePhase.downloading =>
        'Downloading ${status.version}… ${(status.progress * 100).floor()}%',
      UpdatePhase.ready =>
        autoUpdate
            ? '${status.version} is ready and installs when you quit, or '
                  'restart now from the sidebar.'
            : '${status.version} is ready: restart from the sidebar to '
                  'install it.',
      UpdatePhase.failed => '${status.error} $checked',
    };
    final busy =
        status.phase == UpdatePhase.checking ||
        status.phase == UpdatePhase.downloading;

    return _SettingRow(
      title: appVersion.isEmpty
          ? 'Version: local build'
          : 'Version $appVersion',
      description: description,
      control: AppButton(
        label: 'Check now',
        icon: AppIcons.refresh,
        onPressed: status.phase == UpdatePhase.unavailable || busy
            ? null
            : ref.read(updaterProvider.notifier).check,
      ),
    );
  }

  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

/// A labeled settings panel: section label above a bordered surface whose
/// rows are separated by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(label.toUpperCase()),
        const SizedBox(height: AppSpacing.sm),
        AppPanel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Container(height: 1, color: c.borderMuted),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One setting: title + explanation on the left, its control on the right —
/// or, when [stacked], the control full-width beneath the text (long inputs).
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.description,
    required this.control,
    this.stacked = false,
  });

  final String title;
  final String description;
  final Widget control;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.text.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(description, style: context.text.smallMuted),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                text,
                const SizedBox(height: AppSpacing.md),
                control,
              ],
            )
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: AppSpacing.lg),
                control,
              ],
            ),
    );
  }
}

/// A − value + stepper. Buttons null out at the bounds.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            icon: AppIcons.minus,
            size: 13,
            color: onDecrement == null ? c.textFaint : null,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 52,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: context.text.monoSmall.copyWith(color: c.textPrimary),
            ),
          ),
          AppIconButton(
            icon: AppIcons.add,
            size: 13,
            color: onIncrement == null ? c.textFaint : null,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
