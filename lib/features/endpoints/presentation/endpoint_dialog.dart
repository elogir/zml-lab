import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/execution/native_io.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/api_endpoint.dart';
import '../../../repositories/endpoint_repository.dart';

/// Creates (or, with [existing], edits) a saved endpoint: a name, its API
/// root, and an optional key (stored in the Keychain). Resolves to the saved
/// endpoint, or null if cancelled or deleted.
Future<ApiEndpoint?> showEndpointDialog(
  BuildContext context, {
  ApiEndpoint? existing,
}) => showAppDialog<ApiEndpoint>(
  context,
  (context) => _EndpointDialog(existing: existing),
);

class _EndpointDialog extends ConsumerStatefulWidget {
  const _EndpointDialog({this.existing});

  final ApiEndpoint? existing;

  @override
  ConsumerState<_EndpointDialog> createState() => _EndpointDialogState();
}

class _EndpointDialogState extends ConsumerState<_EndpointDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _url = TextEditingController(text: widget.existing?.baseUrl);
  final _key = TextEditingController();
  late bool _hasKey = widget.existing?.hasApiKey ?? false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final url = ChatEndpoint.parseBaseUrl(_url.text);
    if (name.isEmpty || url == null) {
      setState(
        () => _error = name.isEmpty
            ? 'Give it a name.'
            : 'Enter an http(s) URL, e.g. https://api.openai.com/v1',
      );
      return;
    }
    final keys = ref.read(apiKeyStoreProvider);
    final id =
        widget.existing?.id ?? 'ep-${DateTime.now().microsecondsSinceEpoch}';
    final newKey = _key.text.trim();
    // A typed key replaces the stored one; an empty field keeps it (unless
    // removed with "Remove key").
    if (newKey.isNotEmpty) {
      await keys.write(id, newKey);
    } else if (!_hasKey) {
      await keys.delete(id);
    }
    final endpoint = ApiEndpoint(
      id: id,
      name: name,
      baseUrl: url.toString(),
      hasApiKey: newKey.isNotEmpty || _hasKey,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await ref.read(endpointRepositoryProvider).save(endpoint);
    if (mounted) Navigator.of(context).pop(endpoint);
  }

  Future<void> _delete() async {
    final e = widget.existing!;
    await ref.read(apiKeyStoreProvider).delete(e.id);
    await ref.read(endpointRepositoryProvider).delete(e.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editing = widget.existing != null;
    return AppDialogFrame(
      icon: AppIcons.machines,
      title: editing ? 'Edit endpoint' : 'New endpoint',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Name'),
          AppTextField(
            controller: _name,
            autofocus: !editing,
            placeholder: 'OpenAI',
          ),
          const SizedBox(height: AppSpacing.md),
          const FieldLabel('Base URL'),
          AppTextField(
            controller: _url,
            mono: true,
            placeholder: 'https://api.openai.com/v1',
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.md),
          const FieldLabel('API key'),
          AppTextField(
            controller: _key,
            mono: true,
            obscureText: true,
            placeholder: _hasKey
                ? 'saved in Keychain — type to replace'
                : 'optional — sent as Bearer',
            onSubmitted: (_) => _save(),
          ),
          if (_hasKey) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Remove key',
                variant: AppButtonVariant.ghost,
                dense: true,
                onPressed: () => setState(() => _hasKey = false),
              ),
            ),
          ],
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
        if (editing)
          AppButton(
            label: 'Delete',
            icon: AppIcons.delete,
            variant: AppButtonVariant.ghost,
            onPressed: _delete,
          ),
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
