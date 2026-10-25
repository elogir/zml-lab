import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/execution/native_io.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/api_endpoint.dart';
import '../../../repositories/endpoint_repository.dart';

/// Creates (or, with [existing], edits) a saved endpoint: a name, its API
/// root, and an optional key (kept in the [ApiKeyStore]). Resolves to the saved
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
  bool _showKey = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  /// Fills the key field with the saved key, masked until the eye shows it.
  Future<void> _loadKey() async {
    final e = widget.existing;
    if (e == null || !e.hasApiKey) return;
    final key = await ref.read(apiKeyStoreProvider).read(e.id);
    // Unless typing already started.
    if (mounted && key != null && _key.text.isEmpty) _key.text = key;
  }

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
    // The field holds the key itself: emptied, there's none.
    final key = _key.text.trim();
    try {
      key.isEmpty ? await keys.delete(id) : await keys.write(id, key);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save the key: $e');
      return;
    }
    final endpoint = ApiEndpoint(
      id: id,
      name: name,
      baseUrl: url.toString(),
      hasApiKey: key.isNotEmpty,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await ref.read(endpointRepositoryProvider).save(endpoint);
    if (mounted) Navigator.of(context).pop(endpoint);
  }

  Future<void> _delete() async {
    final e = widget.existing!;
    final keys = ref.read(apiKeyStoreProvider);
    // The row first: a key that fails to go mustn't keep the endpoint around.
    await ref.read(endpointRepositoryProvider).delete(e.id);
    if (mounted) Navigator.of(context).pop();
    await keys.delete(e.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editing = widget.existing != null;
    return AppDialogFrame(
      icon: AppIcons.web,
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
            obscureText: !_showKey,
            placeholder: 'optional — sent as Bearer',
            onSubmitted: (_) => _save(),
            suffix: AppIconButton(
              icon: _showKey ? AppIcons.conceal : AppIcons.reveal,
              size: 13,
              padding: const EdgeInsets.all(3),
              onPressed: () => setState(() => _showKey = !_showKey),
            ),
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
