import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// What can be changed on a saved run afterwards: how it's labelled, never
/// what it measured.
class RunDetails {
  const RunDetails({
    required this.name,
    required this.machine,
    this.modelAlias,
    this.notes = '',
  });

  final String name;
  final String machine;

  /// Shown instead of the model the requests named; null = that one.
  final String? modelAlias;
  final String notes;
}

/// Edits a saved run's [current] details (chat and perf runs alike).
/// [sentModel] is the model the requests named, empty if none was recorded:
/// the Model field starts from the alias or it, and an alias that's cleared
/// or equal to it is dropped. Resolves to the new details, or null if
/// cancelled.
Future<RunDetails?> showEditRunDialog(
  BuildContext context, {
  required RunDetails current,
  required String sentModel,
}) => showAppDialog<RunDetails>(
  context,
  (context) => _EditRunDialog(current: current, sentModel: sentModel),
);

class _EditRunDialog extends StatefulWidget {
  const _EditRunDialog({required this.current, required this.sentModel});

  final RunDetails current;
  final String sentModel;

  @override
  State<_EditRunDialog> createState() => _EditRunDialogState();
}

class _EditRunDialogState extends State<_EditRunDialog> {
  late final _name = TextEditingController(text: widget.current.name);
  late final _machine = TextEditingController(text: widget.current.machine);
  late final _model = TextEditingController(
    text: widget.current.modelAlias ?? widget.sentModel,
  );
  late final _notes = TextEditingController(text: widget.current.notes);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _machine.dispose();
    _model.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final machine = _machine.text.trim();
    if (name.isEmpty || machine.isEmpty) {
      setState(
        () => _error = name.isEmpty
            ? 'Give it a name.'
            : 'Say which machine it ran on.',
      );
      return;
    }
    final model = _model.text.trim();
    Navigator.of(context).pop(
      RunDetails(
        name: name,
        machine: machine,
        modelAlias: model.isEmpty || model == widget.sentModel ? null : model,
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppDialogFrame(
      icon: AppIcons.edit,
      title: 'Edit details',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Name'),
          AppTextField(
            controller: _name,
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.md),
          const FieldLabel('Machine'),
          AppTextField(
            controller: _machine,
            mono: true,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.md),
          const FieldLabel('Model'),
          AppTextField(
            controller: _model,
            mono: true,
            placeholder: widget.sentModel.isEmpty ? 'not recorded' : null,
            onSubmitted: (_) => _save(),
          ),
          if (widget.sentModel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sent as ${widget.sentModel}; clear the field to show that.',
              style: context.text.smallMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const FieldLabel('Notes'),
          AppTextField(
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            placeholder: 'build, flags, what you were testing',
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: context.text.small.copyWith(color: c.statusFailed),
            ),
          ],
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Save',
          variant: AppButtonVariant.primary,
          onPressed: _save,
        ),
      ],
    );
  }
}
