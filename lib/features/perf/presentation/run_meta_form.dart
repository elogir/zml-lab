import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/run_meta.dart';

/// The run-details form ([runMetaFields]) that Export run and Edit details
/// share, with the website's labels and order, so a run reads the same
/// wherever it's edited.
class RunMetaForm extends StatelessWidget {
  const RunMetaForm({super.key, required this.fields, this.modelHint});

  /// One controller per [runMetaFields] path (see [controllers]).
  final Map<String, TextEditingController> fields;

  /// A line under Model, e.g. what the requests sent.
  final String? modelHint;

  /// Controllers for [runMetaFields], prefilled from [meta].
  static Map<String, TextEditingController> controllers(
    Map<String, Object?> meta,
  ) => {
    for (final path in runMetaFields)
      path: TextEditingController(text: runMetaField(meta, path)),
  };

  /// The controllers' texts, by path.
  static Map<String, String> texts(Map<String, TextEditingController> fields) =>
      {for (final MapEntry(:key, :value) in fields.entries) key: value.text};

  @override
  Widget build(BuildContext context) {
    Widget field(
      String label,
      String path, {
      String? placeholder,
      bool mono = false,
      int lines = 1,
      String? hint,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label),
          AppTextField(
            controller: fields[path],
            mono: mono,
            placeholder: placeholder,
            minLines: lines,
            maxLines: lines,
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              hint,
              style: context.text.smallMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: b),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field('Name', 'label', placeholder: 'how it reads in charts'),
        field('Model', 'model.name', mono: true, hint: modelHint),
        // Prefilled from the target machine, or what zml-smi saw.
        field(
          'Hardware',
          'hardware.description',
          placeholder: '1× RTX 4090, 64 GB',
        ),
        pair(
          field('Server version', 'server.version', mono: true),
          field(
            'Server commit',
            'server.commit',
            mono: true,
            placeholder: 'a1b2c3d',
          ),
        ),
        field('Tags', 'tags', placeholder: 'comma-separated'),
        field('Notes', 'notes', lines: 3),
      ],
    );
  }
}
