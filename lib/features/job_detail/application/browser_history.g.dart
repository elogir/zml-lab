// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_history.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Visited-URL history for the web tabs' address bar, most-recent first.
/// Backed by drift so it persists across restarts; the in-memory list is a
/// live cache kept in sync as pages are visited.

@ProviderFor(BrowserHistory)
final browserHistoryProvider = BrowserHistoryProvider._();

/// Visited-URL history for the web tabs' address bar, most-recent first.
/// Backed by drift so it persists across restarts; the in-memory list is a
/// live cache kept in sync as pages are visited.
final class BrowserHistoryProvider
    extends $NotifierProvider<BrowserHistory, List<String>> {
  /// Visited-URL history for the web tabs' address bar, most-recent first.
  /// Backed by drift so it persists across restarts; the in-memory list is a
  /// live cache kept in sync as pages are visited.
  BrowserHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browserHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browserHistoryHash();

  @$internal
  @override
  BrowserHistory create() => BrowserHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$browserHistoryHash() => r'2d025750c8bc872a64ea7c49e2f628e0033f93d2';

/// Visited-URL history for the web tabs' address bar, most-recent first.
/// Backed by drift so it persists across restarts; the in-memory list is a
/// live cache kept in sync as pages are visited.

abstract class _$BrowserHistory extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
