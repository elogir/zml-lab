import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/run_recorder.dart';

/// "Export run": the run's meta.json, prefilled with what was detected, to
/// complete (label, server version and commit, notes, tags…); then where to
/// save the `.zmlrun.parquet`. Resolves to the exported path, or null. The
/// hardware isn't asked: it's the target machine's, or what zml-smi saw.
Future<String?> showExportRunDialog(
  BuildContext context, {
  required String runFile,
}) => showAppDialog<String>(
  context,
  (context) => ExportRunDialog(runFile: runFile),
);

/// The meta.json fields the dialog edits, by path ('server.commit' is
/// `meta['server']['commit']`). `tags` is a list, edited comma-separated.
const runMetaFields = [
  'label',
  'model.name',
  'server.version',
  'server.commit',
  'tags',
  'notes',
];

/// [meta]'s value at [path] as the dialog shows it.
@visibleForTesting
String runMetaField(Map<String, Object?> meta, String path) {
  Object? v = meta;
  for (final key in path.split('.')) {
    v = v is Map ? v[key] : null;
  }
  return switch (v) {
    String s => s,
    List l => l.join(', '),
    _ => '',
  };
}

/// [meta] with [fields] (path → text) in: trimmed, tags split on commas,
/// and a blank field removes its key. Sections ('model', 'server'…) are
/// copied, never edited in place.
@visibleForTesting
Map<String, Object?> withRunMetaFields(
  Map<String, Object?> meta,
  Map<String, String> fields,
) {
  final out = Map<String, Object?>.of(meta);
  for (final MapEntry(key: path, value: text) in fields.entries) {
    final keys = path.split('.');
    var into = out;
    for (final key in keys.take(keys.length - 1)) {
      final section = Map<String, Object?>.of(
        (into[key] as Map?)?.cast<String, Object?>() ?? const {},
      );
      into[key] = section;
      into = section;
    }
    final Object value = path == 'tags'
        ? [
            for (final t in text.split(','))
              if (t.trim().isNotEmpty) t.trim(),
          ]
        : text.trim();
    if (value is String && value.isEmpty || value is List && value.isEmpty) {
      into.remove(keys.last);
    } else {
      into[keys.last] = value;
    }
  }
  return out;
}

/// A file name for [label]: word characters, dots and dashes.
String _fileName(String label) {
  final slug = label
      .replaceAll(RegExp(r'[^\w.\- ]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
  return '${slug.isEmpty ? 'run' : slug}.zmlrun.parquet';
}

class ExportRunDialog extends StatefulWidget {
  const ExportRunDialog({super.key, required this.runFile});

  final String runFile;

  @override
  State<ExportRunDialog> createState() => _ExportRunDialogState();
}

class _ExportRunDialogState extends State<ExportRunDialog> {
  Map<String, Object?>? _meta;
  final _fields = {
    for (final path in runMetaFields) path: TextEditingController(),
  };
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final f in _fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final meta = await readRunMeta(widget.runFile) ?? {};
      if (!mounted) return;
      for (final MapEntry(key: path, value: field) in _fields.entries) {
        field.text = runMetaField(meta, path);
      }
      setState(() => _meta = meta);
    } catch (e) {
      if (mounted) setState(() => _error = 'could not read the run: $e');
    }
  }

  Future<void> _export() async {
    final location = await getSaveLocation(
      suggestedName: _fileName(_fields['label']!.text),
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Parquet', extensions: ['parquet']),
      ],
      confirmButtonText: 'Export',
    );
    if (location == null || !mounted) return;
    var out = location.path;
    if (!out.endsWith('.parquet')) out = '$out.zmlrun.parquet';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final meta = withRunMetaFields(_meta!, {
        for (final MapEntry(key: path, value: field) in _fields.entries)
          path: field.text,
      });
      await exportRun(runFile: widget.runFile, meta: meta, out: out);
      if (mounted) Navigator.of(context).pop(out);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'export failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget field(
      String label,
      String path, {
      String? placeholder,
      bool mono = false,
      int lines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label),
          AppTextField(
            controller: _fields[path],
            mono: mono,
            placeholder: placeholder,
            minLines: lines,
            maxLines: lines,
          ),
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
    return AppDialogFrame(
      icon: AppIcons.download,
      title: 'Export run',
      maxWidth: 560,
      body: _meta == null && _error == null
          ? const SizedBox(height: 120)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field('Label', 'label', placeholder: 'how it reads in charts'),
                field('Model', 'model.name', mono: true),
                pair(
                  field('Server version', 'server.version', mono: true),
                  field(
                    'Commit',
                    'server.commit',
                    mono: true,
                    placeholder: 'a1b2c3d',
                  ),
                ),
                field('Tags', 'tags', placeholder: 'comma-separated'),
                field('Notes', 'notes', lines: 3),
                const FieldLabel('Hardware'),
                Text(switch (runMetaField(
                  _meta ?? const {},
                  'hardware.description',
                )) {
                  '' =>
                    'not recorded — pick the target machine, or run '
                        'zml-smi on it',
                  final hardware => hardware,
                }, style: context.text.small.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.md),
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
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: _busy ? 'Exporting' : 'Export',
          icon: AppIcons.download,
          variant: AppButtonVariant.primary,
          onPressed: _busy || _meta == null ? null : _export,
        ),
      ],
    );
  }
}
