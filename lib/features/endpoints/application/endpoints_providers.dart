import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/api_endpoint.dart';
import '../../../repositories/endpoint_repository.dart';

part 'endpoints_providers.g.dart';

@riverpod
Stream<List<ApiEndpoint>> endpointsStream(Ref ref) =>
    ref.watch(endpointRepositoryProvider).watchEndpoints();

/// id → endpoint, for keeping a selected endpoint in sync with edits.
@riverpod
Map<String, ApiEndpoint> endpointMap(Ref ref) {
  final endpoints = ref.watch(endpointsStreamProvider).value ?? const [];
  return {for (final e in endpoints) e.id: e};
}
