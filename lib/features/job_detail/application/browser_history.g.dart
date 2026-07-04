// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_history.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-wide visited-URL history for the web tabs, most-recent first.
/// Shared across every web pane so the address bar can autocomplete from it.

@ProviderFor(BrowserHistory)
final browserHistoryProvider = BrowserHistoryProvider._();

/// Session-wide visited-URL history for the web tabs, most-recent first.
/// Shared across every web pane so the address bar can autocomplete from it.
final class BrowserHistoryProvider
    extends $NotifierProvider<BrowserHistory, List<String>> {
  /// Session-wide visited-URL history for the web tabs, most-recent first.
  /// Shared across every web pane so the address bar can autocomplete from it.
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

String _$browserHistoryHash() => r'462452e9495f29911c34e471000c35917c16d837';

/// Session-wide visited-URL history for the web tabs, most-recent first.
/// Shared across every web pane so the address bar can autocomplete from it.

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
