import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/env_var.dart';
import '../../../models/perf_report.dart';
import '../../../models/settings.dart';
import '../application/settings_controller.dart';

/// App-wide preferences, grouped into panels. Every control writes through to
/// the settings store immediately — there is no save button.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _portStart;
  late final TextEditingController _portEnd;
  late final TextEditingController _prompt;
  late final TextEditingController _batch;
  late final TextEditingController _maxTokens;
  late final TextEditingController _temperature;
  late final TextEditingController _benchModel;
  late final TextEditingController _perfToolDir;
  late final TextEditingController _perfDataset;
  late final TextEditingController _perfDuration;
  late final TextEditingController _perfConcurrency;
  late final TextEditingController _perfMaxTokens;
  late final TextEditingController _perfModel;
  late final TextEditingController _perfDuckdb;
  final List<_EnvRow> _env = [];

  SettingsController get _controller =>
      ref.read(settingsControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsControllerProvider);
    _portStart = TextEditingController(text: '${s.portRangeStart}');
    _portEnd = TextEditingController(text: '${s.portRangeEnd}');
    _prompt = TextEditingController(text: s.benchPrompt);
    _batch = TextEditingController(text: '${s.benchBatchSize}');
    _maxTokens = TextEditingController(text: s.benchMaxTokens?.toString() ?? '');
    _temperature =
        TextEditingController(text: s.benchTemperature?.toString() ?? '');
    _benchModel = TextEditingController(text: s.benchModel);
    _perfToolDir = TextEditingController(text: s.perfToolDir);
    _perfDataset = TextEditingController(text: s.perfDatasetPath);
    _perfDuration =
        TextEditingController(text: '${s.perfParams.durationSeconds}');
    _perfConcurrency =
        TextEditingController(text: '${s.perfParams.concurrency}');
    _perfMaxTokens = TextEditingController(
      text: s.perfParams.maxCompletionTokens?.toString() ?? '',
    );
    _perfModel = TextEditingController(text: s.perfParams.model);
    _perfDuckdb = TextEditingController(text: s.perfDuckdbCommand);
    _env.addAll(s.globalEnv.map(_EnvRow.from));
  }

  @override
  void dispose() {
    _portStart.dispose();
    _portEnd.dispose();
    _prompt.dispose();
    _batch.dispose();
    _maxTokens.dispose();
    _temperature.dispose();
    _benchModel.dispose();
    _perfToolDir.dispose();
    _perfDataset.dispose();
    _perfDuration.dispose();
    _perfConcurrency.dispose();
    _perfMaxTokens.dispose();
    _perfModel.dispose();
    _perfDuckdb.dispose();
    for (final e in _env) {
      e.dispose();
    }
    super.dispose();
  }

  void _commitEnv() => _controller.setGlobalEnv([
    for (final e in _env)
      EnvVar(key: e.keyCtrl.text, value: e.valueCtrl.text),
  ]);

  /// Edits the shared perf-run params (the Perf tab's form reads the same
  /// blob, so a change here shows up there while idle).
  void _patchPerf(PerfParams Function(PerfParams) patch) {
    _controller.setPerfParams(
      patch(ref.read(settingsControllerProvider).perfParams),
    );
  }

  void _addEnv() => setState(() => _env.add(_EnvRow.empty()));

  void _removeEnv(_EnvRow row) {
    setState(() {
      _env.remove(row);
      row.dispose();
    });
    _commitEnv();
  }

  Future<void> _reset() async {
    await ref.read(settingsControllerProvider.notifier).resetAll();
    if (!mounted) return;
    // Mirror the fresh defaults back into the (uncontrolled) fields.
    final s = ref.read(settingsControllerProvider);
    setState(() {
      _portStart.text = '${s.portRangeStart}';
      _portEnd.text = '${s.portRangeEnd}';
      _prompt.text = s.benchPrompt;
      _batch.text = '${s.benchBatchSize}';
      _maxTokens.text = '';
      _temperature.text = '';
      _benchModel.text = '';
      _perfToolDir.text = s.perfToolDir;
      _perfDataset.text = s.perfDatasetPath;
      _perfDuration.text = '${s.perfParams.durationSeconds}';
      _perfConcurrency.text = '${s.perfParams.concurrency}';
      _perfMaxTokens.text = '';
      _perfModel.text = '';
      _perfDuckdb.text = '';
      for (final e in _env) {
        e.dispose();
      }
      _env.clear();
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
                      onDecrement: s.terminalFontSize >
                              SettingsLimits.minTerminalFont
                          ? () => _controller
                                .setTerminalFontSize(s.terminalFontSize - 1)
                          : null,
                      onIncrement: s.terminalFontSize <
                              SettingsLimits.maxTerminalFont
                          ? () => _controller
                                .setTerminalFontSize(s.terminalFontSize + 1)
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
                label: 'Jobs',
                children: [
                  _SettingRow(
                    title: 'Port auto-assign range',
                    description:
                        'New jobs get the first free port in this range.',
                    control: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 76,
                          child: AppTextField(
                            controller: _portStart,
                            mono: true,
                            onChanged: (v) {
                              final n = int.tryParse(v.trim());
                              if (n != null) _controller.setPortRangeStart(n);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text('–', style: context.text.monoSmall),
                        ),
                        SizedBox(
                          width: 76,
                          child: AppTextField(
                            controller: _portEnd,
                            mono: true,
                            onChanged: (v) {
                              final n = int.tryParse(v.trim());
                              if (n != null) _controller.setPortRangeEnd(n);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SettingRow(
                    title: 'Health check interval',
                    description:
                        'How often running jobs\' endpoints are probed.',
                    control: _Stepper(
                      value: '${s.healthIntervalSeconds} s',
                      onDecrement: s.healthIntervalSeconds >
                              SettingsLimits.minHealthInterval
                          ? () => _controller
                                .setHealthInterval(s.healthIntervalSeconds - 1)
                          : null,
                      onIncrement: s.healthIntervalSeconds <
                              SettingsLimits.maxHealthInterval
                          ? () => _controller
                                .setHealthInterval(s.healthIntervalSeconds + 1)
                          : null,
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
                        'What a job\'s benchmark tab starts with. Runs already '
                        'open keep their own prompt.',
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
                        onChanged: (v) => _controller
                            .setBenchMaxTokens(int.tryParse(v.trim())),
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
                        onChanged: (v) => _controller
                            .setBenchTemperature(double.tryParse(v.trim())),
                      ),
                    ),
                  ),
                  _SettingRow(
                    title: 'Model',
                    description:
                        'Sent with each request. vLLM needs the real name; '
                        'llmd ignores it.',
                    stacked: true,
                    control: AppTextField(
                      controller: _benchModel,
                      mono: true,
                      placeholder: 'zml_model',
                      onChanged: _controller.setBenchModel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _Group(
                label: 'Perf benchmark',
                children: [
                  _SettingRow(
                    title: 'Benchmarker directory',
                    description:
                        'The monorepo\'s tools/benchmark — built with go and '
                        'run locally against the job\'s endpoint.',
                    stacked: true,
                    control: AppTextField(
                      controller: _perfToolDir,
                      mono: true,
                      placeholder: defaultPerfToolDir,
                      onChanged: _controller.setPerfToolDir,
                    ),
                  ),
                  _SettingRow(
                    title: 'ShareGPT dataset',
                    description:
                        'The conversations the benchmarker draws prompts from.',
                    stacked: true,
                    control: AppTextField(
                      controller: _perfDataset,
                      mono: true,
                      placeholder: defaultPerfDatasetPath,
                      onChanged: _controller.setPerfDatasetPath,
                    ),
                  ),
                  _SettingRow(
                    title: 'Duration',
                    description: 'How long each run generates load, in seconds.',
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
                        'Empty = don\'t pass --max-completion-tokens (the '
                        'benchmarker uses its own default).',
                    control: SizedBox(
                      width: 96,
                      child: AppTextField(
                        controller: _perfMaxTokens,
                        mono: true,
                        placeholder: 'default',
                        onChanged: (v) {
                          final n = int.tryParse(v.trim());
                          _patchPerf(
                            (p) => p.copyWith(
                              maxCompletionTokens: n != null && n > 0 ? n : null,
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
                    title: 'Warm-up request',
                    description:
                        'Send one request and wait for it before measuring, so '
                        'the run starts on a hot server.',
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
                    title: 'Model',
                    description:
                        'Sent in each request. vLLM needs the real name; llmd '
                        'ignores it. Empty = pull from /v1/models.',
                    stacked: true,
                    control: AppTextField(
                      controller: _perfModel,
                      mono: true,
                      placeholder: 'from /v1/models',
                      onChanged: (v) =>
                          _patchPerf((p) => p.copyWith(model: v.trim())),
                    ),
                  ),
                  _SettingRow(
                    title: 'duckdb copy command',
                    description:
                        '"Copy results" pipes the run\'s raw event CSV through '
                        'this (run in the tool dir). Empty = copy the app\'s own '
                        'render. Needs duckdb installed.',
                    stacked: true,
                    control: AppTextField(
                      controller: _perfDuckdb,
                      mono: true,
                      placeholder:
                          "duckdb -list -header -separator '\\t' "
                          "-c '.read duckdb/report.sql'",
                      onChanged: _controller.setPerfDuckdbCommand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _Group(
                label: 'Environment',
                children: [
                  _SettingRow(
                    title: 'Global variables',
                    description:
                        'Injected into every job launch, local and remote. A '
                        'job\'s own variables override these.',
                    stacked: true,
                    control: _EnvEditor(
                      rows: _env,
                      onAdd: _addEnv,
                      onRemove: _removeEnv,
                      onChanged: _commitEnv,
                    ),
                  ),
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

/// A key/value pair being edited, with its own text controllers.
class _EnvRow {
  _EnvRow({String key = '', String value = ''})
    : keyCtrl = TextEditingController(text: key),
      valueCtrl = TextEditingController(text: value);

  _EnvRow.empty() : this();
  _EnvRow.from(EnvVar e) : this(key: e.key, value: e.value);

  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;

  void dispose() {
    keyCtrl.dispose();
    valueCtrl.dispose();
  }
}

/// An add/remove editor for a list of `KEY=value` rows. Each edit calls
/// [onChanged] so the store stays in sync as you type (empty keys are dropped
/// by the controller).
class _EnvEditor extends StatelessWidget {
  const _EnvEditor({
    required this.rows,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<_EnvRow> rows;
  final VoidCallback onAdd;
  final void Function(_EnvRow) onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isEmpty)
          Text(
            'No global variables set.',
            style: context.text.smallMuted,
          ),
        for (final row in rows) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: row.keyCtrl,
                    placeholder: 'KEY',
                    mono: true,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('=', style: context.text.monoSmall),
                ),
                Expanded(
                  child: AppTextField(
                    controller: row.valueCtrl,
                    placeholder: 'value',
                    mono: true,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppIconButton(
                  icon: AppIcons.close,
                  size: 15,
                  color: c.textMuted,
                  hoverColor: c.statusFailed,
                  onPressed: () => onRemove(row),
                ),
              ],
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'Add variable',
            icon: AppIcons.add,
            variant: AppButtonVariant.ghost,
            dense: true,
            onPressed: onAdd,
          ),
        ),
      ],
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
