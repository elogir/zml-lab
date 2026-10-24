// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sharegpt_dataset.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keep-alive: a download carries on while you look at other tabs.

@ProviderFor(ShareGptDataset)
final shareGptDatasetProvider = ShareGptDatasetProvider._();

/// Keep-alive: a download carries on while you look at other tabs.
final class ShareGptDatasetProvider
    extends $NotifierProvider<ShareGptDataset, DatasetState> {
  /// Keep-alive: a download carries on while you look at other tabs.
  ShareGptDatasetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareGptDatasetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareGptDatasetHash();

  @$internal
  @override
  ShareGptDataset create() => ShareGptDataset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatasetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatasetState>(value),
    );
  }
}

String _$shareGptDatasetHash() => r'6771e22a34e87b5497201b75ddcda8c1a0fd3021';

/// Keep-alive: a download carries on while you look at other tabs.

abstract class _$ShareGptDataset extends $Notifier<DatasetState> {
  DatasetState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DatasetState, DatasetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DatasetState, DatasetState>,
              DatasetState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
