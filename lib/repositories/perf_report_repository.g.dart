// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perf_report_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(perfReportRepository)
final perfReportRepositoryProvider = PerfReportRepositoryProvider._();

final class PerfReportRepositoryProvider
    extends
        $FunctionalProvider<
          PerfReportRepository,
          PerfReportRepository,
          PerfReportRepository
        >
    with $Provider<PerfReportRepository> {
  PerfReportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'perfReportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$perfReportRepositoryHash();

  @$internal
  @override
  $ProviderElement<PerfReportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PerfReportRepository create(Ref ref) {
    return perfReportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PerfReportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PerfReportRepository>(value),
    );
  }
}

String _$perfReportRepositoryHash() =>
    r'bf82ba6eb91ea923585b53d9a4a7d8d6fa2188ea';
