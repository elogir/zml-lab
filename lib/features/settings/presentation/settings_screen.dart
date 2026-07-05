import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
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
  }

  @override
  void dispose() {
    _portStart.dispose();
    _portEnd.dispose();
    _prompt.dispose();
    _batch.dispose();
    _maxTokens.dispose();
    _temperature.dispose();
    super.dispose();
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
