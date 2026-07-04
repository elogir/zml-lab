// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_font.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Raw JetBrains Mono bytes for flterm, which renders text from font data
/// rather than the Flutter font system. Loaded once.

@ProviderFor(terminalFont)
final terminalFontProvider = TerminalFontProvider._();

/// Raw JetBrains Mono bytes for flterm, which renders text from font data
/// rather than the Flutter font system. Loaded once.

final class TerminalFontProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>
        >
    with $FutureModifier<Uint8List>, $FutureProvider<Uint8List> {
  /// Raw JetBrains Mono bytes for flterm, which renders text from font data
  /// rather than the Flutter font system. Loaded once.
  TerminalFontProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terminalFontProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terminalFontHash();

  @$internal
  @override
  $FutureProviderElement<Uint8List> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List> create(Ref ref) {
    return terminalFont(ref);
  }
}

String _$terminalFontHash() => r'986a45be234712641d24694d635dcfd24a8f8558';
