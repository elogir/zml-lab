import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/execution/job_executor.dart';
import '../../../core/execution/native_io.dart';
import '../../../core/util/search.dart';
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
import '../../settings/application/settings_controller.dart';
import '../application/free_port.dart';

/// The custom job builder. Optionally pre-filled from a saved config.
/// Fields are wired to controllers; the launch/save actions are deferred.
class CustomJobScreen extends ConsumerStatefulWidget {
  const CustomJobScreen({
    super.key,
    this.configId,
    this.jobId,
    this.newConfig = false,
  });

  /// Editing an existing config (saves back to it).
  final String? configId;

  /// Editing an existing job (pre-filled from it; saves/relaunches the job,
  /// optionally updating the config it came from).
  final String? jobId;

  /// Opened from the configs tab — frames the page as authoring a config.
  final bool newConfig;

  bool get isEditingJob => jobId != null;

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

  // Edit-job mode: the loaded job, its source config (if any) and name, and
  // whether to also push edits back to that config.
  Job? _job;
  String? _sourceConfigId;
  String? _sourceConfigName;
  bool _alsoUpdateConfig = false;

  @override
  void initState() {
    super.initState();
    _port.addListener(() => _portEdited = true);
    _prefill();
  }

  Future<void> _prefill() async {
    if (widget.jobId != null) {
      await _prefillFromJob(widget.jobId!);
      return;
    }
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

  /// Edit-job mode: pre-fill from the job and remember its source config (so we
  /// can offer to push the edit back to it).
  Future<void> _prefillFromJob(String jobId) async {
    final job = await ref.read(jobRepositoryProvider).jobById(jobId);
    if (job == null || !mounted) return;
    final configName = job.configId == null
        ? null
        : (await ref.read(configRepositoryProvider).configById(job.configId!))
              ?.name;
    if (!mounted) return;
    setState(() {
      _job = job;
      _sourceConfigId = job.configId;
      _sourceConfigName = configName;
      _command.text = job.command;
      _workingDir.text = job.workingDir ?? '';
      _port.text = '${job.port}';
      _portEdited = true;
      _name.text = job.name;
      _description.text = job.description ?? '';
      _selectedMachineId = job.machineId;
      _env
        ..clear()
        ..addAll(job.env.map((e) => _EnvEntry(key: e.key, value: e.value)));
    });
  }

  /// Fills the port with a genuinely free one from the configured range,
  /// avoiding ports already claimed by active jobs. Reads the jobs table
  /// directly (not the stream, which may still be loading) so the avoid-set is
  /// never empty by accident. Skipped once the user (or a config) has set the
  /// port.
  Future<void> _prefillFreePort() async {
    final jobs = await ref.read(jobRepositoryProvider).allJobs();
    final taken = {
      for (final j in jobs)
        if (j.status.isActive) j.port,
    };
    final s = ref.read(settingsControllerProvider);
    final port = await findFreePort(
      start: s.portRangeStart,
      // Guard a misconfigured range (end at/below start) to one candidate.
      end: s.portRangeEnd > s.portRangeStart
          ? s.portRangeEnd
          : s.portRangeStart + 1,
      avoid: taken,
    );
    if (!mounted || _portEdited) return;
    setState(() => _port.text = '$port');
  }

  /// Manually pick a fresh free port for the selected machine — a deliberate
  /// action (the button next to the port), so it overrides an edited port.
  Future<void> _findFreePort() async {
    final machines = ref.read(machinesStreamProvider).value ?? const [];
    final machineId =
        _selectedMachineId ?? (machines.isNotEmpty ? machines.first.id : null);
    if (machineId == null) return;
    final port = await freePortForMachine(ref, machineId);
    if (!mounted) return;
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

  /// Back to wherever the form was opened from (jobs, configs, …); the form
  /// is pushed, so a plain pop restores the previous screen and tab.
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

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
      // Editing a job keeps its id (and its source-config link); otherwise a
      // fresh job. A job launched from an edited config links to that config.
      id: widget.jobId ?? 'job-${DateTime.now().microsecondsSinceEpoch}',
      name: typedName.isEmpty ? (autoName.isEmpty ? 'job' : autoName) : typedName,
      description: description.isEmpty ? null : description,
      machineId: machineId,
      command: command,
      workingDir: workingDir.isEmpty ? null : workingDir,
      port: port,
      status: JobStatus.starting,
      env: env,
      configId: widget.isEditingJob ? _sourceConfigId : widget.configId,
    );
    return (job, machine);
  }

  /// Saves the form as a config — updating in place when [configId] (or the
  /// form's own `configId`) is given; editing must not spawn a copy.
  Future<void> _saveConfigFrom(Job job, {String? configId}) => ref
      .read(configRepositoryProvider)
      .upsertConfig(
        LaunchConfig(
          id: configId ??
              widget.configId ??
              'cfg-${DateTime.now().microsecondsSinceEpoch}',
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

  /// Edit-job mode. Writes the edited fields to the job (and, when
  /// [_alsoUpdateConfig], back to its source config), then optionally
  /// relaunches so the change takes effect.
  Future<void> _saveJob({required bool relaunch}) async {
    final resolved = _resolve();
    if (resolved == null) return;
    final (job, machine) = resolved;
    if (_alsoUpdateConfig && _sourceConfigId != null) {
      await _saveConfigFrom(job, configId: _sourceConfigId);
    }
    final executor = ref.read(jobExecutorProvider);
    if (relaunch) {
      // restart handles both a live job (SIGINT then respawn) and a stopped
      // one (just spawn); either way it persists the edited job.
      await executor.restart(job, machine);
    } else {
      // Keep the current status/pid — just update the stored spec so the next
      // manual restart uses it.
      await ref.read(jobRepositoryProvider).upsertJob(
        job.copyWith(
          status: _job?.status ?? job.status,
          pid: _job?.pid,
          startedAt: _job?.startedAt,
        ),
      );
    }
    if (!mounted) return;
    context.go('/jobs/${job.id}');
  }

  List<Widget> _editJobActions() {
    final configName = _sourceConfigName == null
        ? 'the saved config'
        : 'config “$_sourceConfigName”';
    return [
      if (_sourceConfigId != null) ...[
        _CheckRow(
          checked: _alsoUpdateConfig,
          label: 'Also update $configName',
          onChanged: (v) => setState(() => _alsoUpdateConfig = v),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      Row(
        children: [
          AppButton(
            label: 'Save & relaunch',
            icon: LucideIcons.play,
            variant: AppButtonVariant.primary,
            onPressed: () => _saveJob(relaunch: true),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: 'Save without relaunching',
            onPressed: () => _saveJob(relaunch: false),
          ),
        ],
      ),
    ];
  }

  String get _headerTitle {
    if (widget.isEditingJob) return 'Edit job';
    if (widget.configId != null) return 'Edit config';
    if (widget.newConfig) return 'New config';
    return 'New custom job';
  }

  String get _headerSubtitle {
    if (widget.isEditingJob) {
      return 'Update this job and relaunch — handy after a launch fails on a '
          'typo. Optionally push the fix back to its saved config.';
    }
    if (widget.configId != null) {
      return 'Changes save back to this config; launching uses the edited '
          'values.';
    }
    if (widget.newConfig) {
      return 'Configure the process and save it as a reusable config; you can '
          'launch it too.';
    }
    return 'Configure the process, then launch or save it as a reusable '
        'config.';
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
              BackLink(label: 'Back', onTap: _back),
              const SizedBox(height: AppSpacing.md),
              Text(_headerTitle, style: context.text.title),
              const SizedBox(height: 4),
              Text(_headerSubtitle, style: context.text.subtitle),
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
                // build && run the binary directly: `bazel run` would hold the
                // workspace lock for the server's whole lifetime, so a second
                // job on the same machine could never start.
                placeholder:
                    'bazel build --@zml//platforms:metal=true //llmd:llmd && '
                    'bazel-bin/llmd/llmd --model … --listen 0.0.0.0:\$PORT',
                controller: _command,
                mono: true,
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: AppSpacing.xl),

              _PortSection(controller: _port, onFindPort: _findFreePort),
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
              if (widget.isEditingJob)
                ..._editJobActions()
              else
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
                    AppButton(
                      label: 'Save config only',
                      onPressed: _saveConfigOnly,
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
      matchesSearch(q, [m.name, m.address, m.gpus]);

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
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

class _MachineOption extends ConsumerWidget {
  const _MachineOption({
    required this.machine,
    required this.selected,
    required this.onTap,
  });

  final Machine machine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final up = ref.watch(machineReachableProvider(machine.id)).value;
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
                  color: up == null
                      ? c.textMuted
                      : up
                      ? c.statusRunning
                      : c.statusFailed,
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
  const _PortSection({required this.controller, required this.onFindPort});

  final TextEditingController controller;

  /// Pick a fresh free port for the selected machine (the button beside the
  /// field). Manual so it never surprises an intentionally-set port.
  final VoidCallback onFindPort;

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
        Row(
          children: [
            SizedBox(
              width: 160,
              child: AppTextField(controller: controller, mono: true),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppIconButton(
              icon: AppIcons.refresh,
              size: 16,
              onPressed: onFindPort,
            ),
            const SizedBox(width: 6),
            Text(
              'find free',
              style: context.text.smallMuted,
            ),
          ],
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

/// A simple tappable checkbox + label (the app has no Material Checkbox).
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.checked,
    required this.label,
    required this.onChanged,
  });

  final bool checked;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HoverRegion(
      onTap: () => onChanged(!checked),
      builder: (context, hovered) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: checked ? c.accent : c.surfaceMuted,
              borderRadius: AppRadius.smAll,
              border: Border.all(
                color: checked
                    ? c.accent
                    : (hovered ? c.borderStrong : c.border),
              ),
            ),
            child: checked
                ? const Icon(AppIcons.check, size: 13, color: Color(0xFFFFFFFF))
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: context.text.body),
        ],
      ),
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
