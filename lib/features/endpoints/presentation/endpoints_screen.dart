import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/util/search.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/api_endpoint.dart';
import '../../../repositories/endpoint_repository.dart';
import '../../perf/application/benchmark_target.dart';
import '../../settings/application/settings_controller.dart';
import '../application/endpoints_providers.dart';
import 'endpoint_dialog.dart';

class EndpointsScreen extends ConsumerStatefulWidget {
  const EndpointsScreen({super.key});

  @override
  ConsumerState<EndpointsScreen> createState() => _EndpointsScreenState();
}

class _EndpointsScreenState extends ConsumerState<EndpointsScreen> {
  String _query = '';

  bool _matches(ApiEndpoint e, String q) =>
      matchesSearch(q, [e.name, e.baseUrl]);

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(endpointsStreamProvider).value ?? const [];
    final q = _query.trim();
    final endpoints = q.isEmpty
        ? all
        : all.where((e) => _matches(e, q)).toList();

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Endpoints',
            subtitle:
                '${all.length} ${all.length == 1 ? 'API' : 'APIs'} to benchmark against.',
            trailing: AppButton(
              label: 'Add endpoint',
              icon: AppIcons.add,
              variant: AppButtonVariant.primary,
              onPressed: () => showEndpointDialog(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSearchField(
            hintText: 'Search endpoints',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: endpoints.isEmpty
                ? Center(
                    child: Text(
                      q.isEmpty ? 'No endpoints' : 'No matching endpoints',
                      style: context.text.smallMuted,
                    ),
                  )
                : SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = AppSpacing.lg;
                        final width = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final endpoint in endpoints)
                              SizedBox(
                                width: width,
                                child: _EndpointCard(endpoint: endpoint),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EndpointCard extends ConsumerWidget {
  const _EndpointCard({required this.endpoint});

  final ApiEndpoint endpoint;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    // Read before the dialog: the card may be gone (deleted) once it closes.
    final target = ref.read(benchmarkTargetControllerProvider.notifier);
    final saved = await showEndpointDialog(context, existing: endpoint);
    // A replaced or removed key changes no row, so tell the Benchmark tab's
    // target (if it's on this endpoint) to re-read it.
    if (saved != null) await target.reloadKey(saved.id);
  }

  Future<void> _delete(WidgetRef ref) async {
    final keys = ref.read(apiKeyStoreProvider);
    final repo = ref.read(endpointRepositoryProvider);
    // The row first: a key that fails to go mustn't keep the endpoint around.
    await repo.delete(endpoint.id);
    await keys.delete(endpoint.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final blurHost = ref.watch(
      settingsControllerProvider.select((s) => s.blurHost),
    );

    return AppCard(
      onTap: () => _edit(context, ref),
      onDelete: () => _delete(ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.web, size: 13, color: c.textFaint),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  endpoint.name,
                  style: context.text.mono.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailRow(
            label: 'URL',
            value: blurHost ? maskHost(endpoint.baseUrl) : endpoint.baseUrl,
          ),
          // A fixed run of bullets, so the mask doesn't give away the key's
          // length; the edit dialog can show it.
          _DetailRow(
            label: 'API key',
            value: endpoint.hasApiKey ? '•' * 16 : '—',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: context.text.smallMuted),
          ),
          Expanded(
            child: Text(
              value,
              style: context.text.monoSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
