import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/run_meta.dart';
import '../domain/run_recorder.dart';
import 'run_meta_form.dart';

/// "Export run": the run's meta.json, prefilled with what was detected (the
/// hardware from the target machine or zml-smi), to correct and complete
/// (name, server version and commit, notes, tags…); then where to save the
/// `.jsonl.gz`. [overrides] (path → text) go over the file's values: a
/// saved run's name and model, as ZML-Lab shows them. Resolves to the
/// exported path, or null.
Future<String?> showExportRunDialog(
  BuildContext context, {
  required String runFile,
  Map<String, String> overrides = const {},
}) => showAppDialog<String>(
  context,
  (context) => ExportRunDialog(runFile: runFile, overrides: overrides),
);

/// A file name for [label]: word characters, dots and dashes.
String _fileName(String label) {
  final slug = label
      .replaceAll(RegExp(r'[^\w.\- ]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
  return '${slug.isEmpty ? 'run' : slug}$runFileExtension';
}

class ExportRunDialog extends StatefulWidget {
  const ExportRunDialog({
    super.key,
    required this.runFile,
    this.overrides = const {},
  });

  final String runFile;
  final Map<String, String> overrides;

  @override
  State<ExportRunDialog> createState() => _ExportRunDialogState();
}

class _ExportRunDialogState extends State<ExportRunDialog> {
  Map<String, Object?>? _meta;
  final _fields = RunMetaForm.controllers(const {});
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
      final meta = withRunMetaFields(
        await readRunMeta(widget.runFile) ?? {},
        widget.overrides,
      );
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
        XTypeGroup(label: 'Perf run', extensions: ['gz']),
      ],
      confirmButtonText: 'Export',
    );
    if (location == null || !mounted) return;
    var out = location.path;
    if (!out.endsWith(runFileExtension)) {
      out =
          '${out.replaceFirst(RegExp(r'(\.jsonl)?(\.gz)?$'), '')}'
          '$runFileExtension';
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final meta = withRunMetaFields(
        _meta!,
        changedRunMetaFields(_meta!, RunMetaForm.texts(_fields)),
      );
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
    return AppDialogFrame(
      icon: AppIcons.download,
      title: 'Export run',
      maxWidth: 560,
      body: _meta == null && _error == null
          ? const SizedBox(height: 120)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RunMetaForm(fields: _fields),
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
