import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/run_meta.dart';
import '../../perf/presentation/run_meta_form.dart';

/// Edits a saved run's details: the [runMetaFields] of [meta], as Export run
/// and the website's run page do, under the same rules — trimmed, only what
/// changed is written, a cleared field drops its key, every other key of
/// [meta] kept as is. [sentModel] is the model the requests named: a cleared
/// Model field puts it back. Resolves to the new meta.json, or null if
/// cancelled.
Future<Map<String, Object?>?> showEditRunDialog(
  BuildContext context, {
  required Map<String, Object?> meta,
  String sentModel = '',
}) => showAppDialog<Map<String, Object?>>(
  context,
  (context) => _EditRunDialog(meta: meta, sentModel: sentModel),
);

class _EditRunDialog extends StatefulWidget {
  const _EditRunDialog({required this.meta, required this.sentModel});

  final Map<String, Object?> meta;
  final String sentModel;

  @override
  State<_EditRunDialog> createState() => _EditRunDialogState();
}

class _EditRunDialogState extends State<_EditRunDialog> {
  late final _fields = RunMetaForm.controllers(widget.meta);
  String? _error;

  @override
  void dispose() {
    for (final f in _fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _save() {
    final texts = RunMetaForm.texts(_fields);
    if (texts['label']!.trim().isEmpty) {
      setState(() => _error = 'Give it a name.');
      return;
    }
    if (texts['model.name']!.trim().isEmpty) {
      texts['model.name'] = widget.sentModel;
    }
    Navigator.of(context).pop(
      withRunMetaFields(widget.meta, changedRunMetaFields(widget.meta, texts)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppDialogFrame(
      icon: AppIcons.edit,
      title: 'Edit details',
      maxWidth: 560,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RunMetaForm(
            fields: _fields,
            modelHint: widget.sentModel.isEmpty
                ? null
                : 'Sent as ${widget.sentModel}; clear the field to show that.',
          ),
          if (_error != null)
            Text(
              _error!,
              style: context.text.small.copyWith(color: c.statusFailed),
            ),
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
