import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/machine.dart';
import '../../../repositories/config_repository.dart';
import '../../machines/application/machines_providers.dart';

/// The custom job builder. Optionally pre-filled from a saved config.
/// Fields are wired to controllers; the launch/save actions are deferred.
class CustomJobScreen extends ConsumerStatefulWidget {
  const CustomJobScreen({super.key, this.configId});

  final String? configId;

  @override
  ConsumerState<CustomJobScreen> createState() => _CustomJobScreenState();
}

class _EnvEntry {
  _EnvEntry({String key = '', String value = ''})
    : keyCtrl = TextEditingController(text: key),
      valueCtrl = TextEditingController(text: value);
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;

  void dispose() {
    keyCtrl.dispose();
    valueCtrl.dispose();
  }
}

class _CustomJobScreenState extends ConsumerState<CustomJobScreen> {
  final _workingDir = TextEditingController();
  final _command = TextEditingController();
  final _port = TextEditingController(text: '8005');
  final _name = TextEditingController();
  final _description = TextEditingController();
  final List<_EnvEntry> _env = [];
  String? _selectedMachineId;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final id = widget.configId;
    if (id == null) return;
    final config = await ref.read(configRepositoryProvider).configById(id);
    if (config == null || !mounted) return;
    setState(() {
      _command.text = config.command;
      _workingDir.text = config.workingDir ?? '';
      _port.text = '${config.port}';
      _name.text = config.name;
      _description.text = config.description ?? '';
      _selectedMachineId = config.machineId;
      _env
        ..clear()
        ..addAll(config.env.map((e) => _EnvEntry(key: e.key, value: e.value)));
    });
  }

  @override
  void dispose() {
    _workingDir.dispose();
    _command.dispose();
    _port.dispose();
    _name.dispose();
    _description.dispose();
    for (final e in _env) {
      e.dispose();
    }
    super.dispose();
  }

  void _back() => context.go('/');

  @override
  Widget build(BuildContext context) {
    final machines = ref.watch(machinesStreamProvider).value ?? const [];
    final selectedId =
        _selectedMachineId ?? (machines.isNotEmpty ? machines.first.id : null);

    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackLink(label: 'Back to jobs', onTap: _back),
              const SizedBox(height: AppSpacing.md),
              Text('New custom job', style: context.text.title),
              const SizedBox(height: 4),
              Text(
                'Configure the process, then launch or save it as a reusable config.',
                style: context.text.subtitle,
              ),
              const SizedBox(height: AppSpacing.xl),

              const _SectionTitle(1, 'Machine'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (final machine in machines) ...[
                    Expanded(
                      child: _MachineOption(
                        machine: machine,
                        selected: machine.id == selectedId,
                        onTap: () =>
                            setState(() => _selectedMachineId = machine.id),
                      ),
                    ),
                    if (machine != machines.last)
                      const SizedBox(width: AppSpacing.md),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              const _SectionTitle(2, 'Command'),
              const SizedBox(height: AppSpacing.md),
              LabeledInput(
                label: 'Working directory',
                hint: 'optional',
                prefix: 'cd:',
                placeholder: '~/src/llm-d',
                controller: _workingDir,
                mono: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledInput(
                label: 'Command line',
                prefix: '\$',
                placeholder:
                    'llm-d serve --model meta-llama/Llama-3.1-8B-Instruct '
                    '--tensor-parallel-size 2',
                controller: _command,
                mono: true,
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: AppSpacing.xl),

              _PortSection(controller: _port),
              const SizedBox(height: AppSpacing.xl),

              _EnvSection(
                entries: _env,
                onAdd: () => setState(() => _env.add(_EnvEntry())),
                onRemove: (entry) => setState(() {
                  _env.remove(entry);
                  entry.dispose();
                }),
              ),
              const SizedBox(height: AppSpacing.xl),

              const _SectionTitle(3, 'Name & description'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _name, placeholder: 'job name'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _description,
                placeholder: 'short description (optional)',
              ),
              const SizedBox(height: AppSpacing.xl),

              Container(height: 1, color: context.colors.borderMuted),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  AppButton(
                    label: 'Save & launch',
                    icon: LucideIcons.play,
                    variant: AppButtonVariant.primary,
                    onPressed: _back,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(label: 'Launch without saving', onPressed: _back),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(label: 'Save config only', onPressed: _back),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.number, this.label);

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Text('$number', style: context.text.monoSmall.copyWith(color: c.textFaint)),
        const SizedBox(width: AppSpacing.sm),
        Text(label.toUpperCase(), style: context.text.sectionLabel),
      ],
    );
  }
}

class _MachineOption extends StatelessWidget {
  const _MachineOption({
    required this.machine,
    required this.selected,
    required this.onTap,
  });

  final Machine machine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      selected: selected,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: machine.online ? c.statusRunning : c.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                machine.name,
                style: context.text.mono.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (selected)
                Icon(LucideIcons.circleCheck, size: 16, color: c.textPrimary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(machine.gpus ?? '—', style: context.text.monoSmall),
          const SizedBox(height: 2),
          Text(machine.memory ?? '—', style: context.text.monoSmall),
        ],
      ),
    );
  }
}

class _PortSection extends StatelessWidget {
  const _PortSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Port',
              style: context.text.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Text(
              'auto-assigned (free)',
              style: context.text.small.copyWith(color: c.statusRunning),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: 160,
          child: AppTextField(controller: controller, mono: true),
        ),
      ],
    );
  }
}

class _EnvSection extends StatelessWidget {
  const _EnvSection({
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_EnvEntry> entries;
  final VoidCallback onAdd;
  final void Function(_EnvEntry) onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Environment variables',
              style: context.text.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            AppButton(
              label: 'Add variable',
              icon: AppIcons.add,
              variant: AppButtonVariant.ghost,
              dense: true,
              onPressed: onAdd,
            ),
          ],
        ),
        for (final entry in entries) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: entry.keyCtrl,
                  placeholder: 'KEY',
                  mono: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('=', style: context.text.monoSmall),
              ),
              Expanded(
                child: AppTextField(
                  controller: entry.valueCtrl,
                  placeholder: 'value',
                  mono: true,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIconButton(
                icon: AppIcons.close,
                size: 15,
                color: c.textMuted,
                onPressed: () => onRemove(entry),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
