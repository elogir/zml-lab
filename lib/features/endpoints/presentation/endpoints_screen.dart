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
                // A row each: there's only a name, a URL and a key to show.
                : ListView.separated(
                    itemCount: endpoints.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) =>
                        _EndpointRow(endpoint: endpoints[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EndpointRow extends ConsumerWidget {
  const _EndpointRow({required this.endpoint});

  final ApiEndpoint endpoint;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    // Read before the dialog: the row may be gone (deleted) once it closes.
    final target = ref.read(benchmarkTargetControllerProvider.notifier);
    final saved = await showEndpointDialog(context, existing: endpoint);
    // A replaced or removed key changes no row, so tell the Benchmark tab's
    // target (if it's on this endpoint) to re-read it.
    if (saved != null) await target.reloadKey(saved.id);
  }

  Future<void> _delete(WidgetRef ref) async {
    final keys = ref.read(apiKeyStoreProvider);
    final repo = ref.read(endpointRepositoryProvider);
    await keys.delete(endpoint.id);
    await repo.delete(endpoint.id);
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
      // 10 vertical centers the line on the card's fixed top-right slot.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      radius: AppRadius.mdAll,
      // Swaps with the delete button on hover.
      topRight: Text(
        endpoint.hasApiKey ? 'key saved' : 'no key',
        style: context.text.smallMuted,
      ),
      child: Row(
        children: [
          Icon(AppIcons.web, size: 13, color: c.textFaint),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 200,
            child: Text(
              endpoint.name,
              style: context.text.mono.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              blurHost ? maskHost(endpoint.baseUrl) : endpoint.baseUrl,
              style: context.text.monoSmall.copyWith(color: c.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Room for the key status / delete button pinned top-right.
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}
