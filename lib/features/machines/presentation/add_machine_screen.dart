import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/machine.dart';
import '../../../repositories/machine_repository.dart';

/// Register a new remote host, or edit an existing one (when [machineId] is
/// set). Saves through the repository (a real drift upsert).
class AddMachineScreen extends ConsumerStatefulWidget {
  const AddMachineScreen({super.key, this.machineId});

  final String? machineId;

  @override
  ConsumerState<AddMachineScreen> createState() => _AddMachineScreenState();
}

class _AddMachineScreenState extends ConsumerState<AddMachineScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _port = TextEditingController(text: '22');
  final _user = TextEditingController();
  final _sshKey = TextEditingController();
  final _gpus = TextEditingController();
  final _memory = TextEditingController();

  /// The loaded machine when editing — kept to preserve fields not on the form
  /// (vendor, online).
  Machine? _original;

  bool get _isEditing => widget.machineId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _load();
  }

  Future<void> _load() async {
    final machine = await ref
        .read(machineRepositoryProvider)
        .machineById(widget.machineId!);
    if (machine == null || !mounted) return;
    setState(() {
      _original = machine;
      _name.text = machine.name;
      _address.text = machine.address;
      _port.text = '${machine.sshPort}';
      _user.text = machine.user ?? '';
      _sshKey.text = machine.sshKey ?? '';
      _gpus.text = machine.gpus ?? '';
      _memory.text = machine.memory ?? '';
    });
  }

  @override
  void dispose() {
    for (final ctrl in [
      _name,
      _address,
      _port,
      _user,
      _sshKey,
      _gpus,
      _memory,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();

  void _save() {
    final machine = Machine(
      id: _original?.id ?? 'm-${DateTime.now().microsecondsSinceEpoch}',
      name: _orNull(_name.text) ?? 'machine',
      address: _orNull(_address.text) ?? '',
      sshPort: int.tryParse(_port.text) ?? 22,
      user: _orNull(_user.text),
      sshKey: _orNull(_sshKey.text),
      vendor: _original?.vendor,
      gpus: _orNull(_gpus.text),
      memory: _orNull(_memory.text),
      online: _original?.online ?? true,
    );
    ref.read(machineRepositoryProvider).upsertMachine(machine);
    _back();
  }

  void _back() => context.go('/machines');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackLink(label: 'Back to machines', onTap: _back),
              const SizedBox(height: AppSpacing.md),
              Text(
                _isEditing ? 'Edit machine' : 'Add a machine',
                style: context.text.title,
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Update this remote host.'
                    : 'Register a remote host so jobs can be launched on it.',
                style: context.text.subtitle,
              ),
              const SizedBox(height: AppSpacing.xl),

              LabeledInput(
                label: 'Name',
                placeholder: 'orion',
                controller: _name,
                mono: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledInput(
                      label: 'Address',
                      placeholder: 'host.example.com',
                      controller: _address,
                      mono: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 110,
                    child: LabeledInput(
                      label: 'Port',
                      placeholder: '22',
                      controller: _port,
                      mono: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              LabeledInput(
                label: 'User',
                hint: 'optional',
                placeholder: 'ubuntu',
                controller: _user,
                mono: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              LabeledInput(
                label: 'SSH key',
                hint: 'optional',
                placeholder: '~/.ssh/id_ed25519',
                controller: _sshKey,
                mono: true,
              ),
              const SizedBox(height: AppSpacing.xl),

              Container(height: 1, color: context.colors.borderMuted),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel('Hardware'),
              const SizedBox(height: 2),
              Text(
                'optional, otherwise detected on connect',
                style: context.text.smallMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledInput(
                      label: 'GPUs',
                      placeholder: '2× RTX 5090',
                      controller: _gpus,
                      mono: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: LabeledInput(
                      label: 'Memory',
                      placeholder: '2× 32 GB',
                      controller: _memory,
                      mono: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  AppButton(
                    label: _isEditing ? 'Save changes' : 'Add machine',
                    icon: _isEditing ? null : AppIcons.add,
                    variant: AppButtonVariant.primary,
                    onPressed: _save,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(label: 'Cancel', onPressed: _back),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
