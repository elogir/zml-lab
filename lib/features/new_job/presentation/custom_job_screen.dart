import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/execution/job_executor.dart';
import '../../../core/execution/native_io.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/enums.dart';
import '../../../models/env_var.dart';
import '../../../models/job.dart';
import '../../../models/launch_config.dart';
import '../../../models/machine.dart';
import '../../../repositories/config_repository.dart';
import '../../../repositories/job_repository.dart';
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
  String _machineQuery = '';
  bool _portEdited = false;

  @override
  void initState() {
    super.initState();
    _port.addListener(() => _portEdited = true);
    _prefill();
  }

  Future<void> _prefill() async {
    final id = widget.configId;
    if (id == null) {
      _prefillFreePort();
      return;
    }
    final config = await ref.read(configRepositoryProvider).configById(id);
    if (config == null || !mounted) return;
    setState(() {
      _command.text = config.command;
      _workingDir.text = config.workingDir ?? '';
      _port.text = '${config.port}';
      _portEdited = true; // came from the config; don't overwrite it
      _name.text = config.name;
      _description.text = config.description ?? '';
      _selectedMachineId = config.machineId;
      _env
        ..clear()
        ..addAll(config.env.map((e) => _EnvEntry(key: e.key, value: e.value)));
    });
  }

  /// Fills the port with a genuinely free one, avoiding ports already claimed
  /// by active jobs. Reads the jobs table directly (not the stream, which may
  /// still be loading) so the avoid-set is never empty by accident. Skipped
  /// once the user (or a config) has set the port.
  Future<void> _prefillFreePort() async {
    final jobs = await ref.read(jobRepositoryProvider).allJobs();
    final taken = {
      for (final j in jobs)
        if (j.status.isActive) j.port,
    };
    final port = await findFreePort(avoid: taken);
    if (!mounted || _portEdited) return;
    setState(() => _port.text = '$port');
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

  /// Reads the form into a Job + its target Machine, or null if it's not
  /// launchable yet (no command, no machine, or an unparseable port).
  (Job, Machine)? _resolve() {
    final machines = ref.read(machinesStreamProvider).value ?? const [];
    final machineId =
        _selectedMachineId ?? (machines.isNotEmpty ? machines.first.id : null);
    if (machineId == null) return null;
    final machine = ref.read(machineMapProvider)[machineId];
    if (machine == null) return null;

    final command = _command.text.trim();
    if (command.isEmpty) return null;
    final port = int.tryParse(_port.text.trim());
    if (port == null) return null;

    final env = [
      for (final e in _env)
        if (e.keyCtrl.text.trim().isNotEmpty)
          EnvVar(key: e.keyCtrl.text.trim(), value: e.valueCtrl.text),
    ];
    final typedName = _name.text.trim();
    final description = _description.text.trim();
    final workingDir = _workingDir.text.trim();

    final autoName = command.trim().split(RegExp(r'\s+')).first.split('/').last;
    final job = Job(
      id: 'job-${DateTime.now().microsecondsSinceEpoch}',
      name: typedName.isEmpty ? (autoName.isEmpty ? 'job' : autoName) : typedName,
      description: description.isEmpty ? null : description,
      machineId: machineId,
      command: command,
      workingDir: workingDir.isEmpty ? null : workingDir,
      port: port,
      status: JobStatus.starting,
      env: env,
    );
    return (job, machine);
  }

  Future<void> _saveConfigFrom(Job job) => ref
      .read(configRepositoryProvider)
      .upsertConfig(
        LaunchConfig(
          id: 'cfg-${DateTime.now().microsecondsSinceEpoch}',
          name: job.name,
          description: job.description,
          machineId: job.machineId,
          command: job.command,
          workingDir: job.workingDir,
          port: job.port,
          env: job.env,
        ),
      );

  Future<void> _launch({required bool save}) async {
    final resolved = _resolve();
    if (resolved == null) return;
    final (job, machine) = resolved;
    if (save) await _saveConfigFrom(job);
    await ref.read(jobExecutorProvider).launch(job, machine);
    if (!mounted) return;
    context.go('/jobs/${job.id}');
  }

  Future<void> _saveConfigOnly() async {
    final resolved = _resolve();
    if (resolved == null) return;
    await _saveConfigFrom(resolved.$1);
    if (!mounted) return;
    _back();
  }

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
              // Search only earns its place once the fleet outgrows the grid.
              if (machines.length > 4) ...[
                AppSearchField(
                  hintText: 'Search machines',
                  onChanged: (v) => setState(() => _machineQuery = v),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _MachineGrid(
                machines: machines,
                query: _machineQuery,
                selectedId: selectedId,
                onSelect: (id) => setState(() => _selectedMachineId = id),
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
                hint: 'use \$PORT for the port',
                prefix: '\$',
                placeholder:
                    'bazel run --@zml//platforms:metal=true //llmd:llmd -- '
                    '--model … --listen 127.0.0.1:\$PORT',
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
                    onPressed: () => _launch(save: true),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: 'Launch without saving',
                    onPressed: () => _launch(save: false),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(label: 'Save config only', onPressed: _saveConfigOnly),
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

/// The machine picker: a two-column grid of machine cards that caps at two
/// rows and scrolls beyond that, so a big fleet doesn't swallow the form.
class _MachineGrid extends StatelessWidget {
  const _MachineGrid({
    required this.machines,
    required this.query,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Machine> machines;
  final String query;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  static const double _cardExtent = 102;
  static const double _gap = AppSpacing.md;

  bool _matches(Machine m, String q) =>
      m.name.toLowerCase().contains(q) ||
      m.address.toLowerCase().contains(q) ||
      (m.gpus?.toLowerCase().contains(q) ?? false);

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final visible = q.isEmpty
        ? machines
        : [
            for (final m in machines)
              if (_matches(m, q)) m,
          ];

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          machines.isEmpty ? 'No machines yet' : 'No matching machines',
          style: context.text.smallMuted,
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 2 * _cardExtent + _gap),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: _gap,
          mainAxisSpacing: _gap,
          mainAxisExtent: _cardExtent,
        ),
        itemCount: visible.length,
        itemBuilder: (context, i) {
          final machine = visible[i];
          return _MachineOption(
            machine: machine,
            selected: machine.id == selectedId,
            onTap: () => onSelect(machine.id),
          );
        },
      ),
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
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Substituted into the command wherever you write \$PORT.',
          style: context.text.smallMuted,
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
