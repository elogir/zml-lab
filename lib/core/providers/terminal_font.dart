import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terminal_font.g.dart';

/// Raw JetBrains Mono bytes for flterm, which renders text from font data
/// rather than the Flutter font system. Loaded once.
@Riverpod(keepAlive: true)
Future<Uint8List> terminalFont(Ref ref) async {
  final data = await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf');
  return data.buffer.asUint8List();
}
