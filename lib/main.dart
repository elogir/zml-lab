import 'package:flterm/flterm.dart' show initializeForWeb;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // flterm renders via a WASM build of the Ghostty VT engine on web.
    // Keep it non-fatal: if the engine fails to init, the rest of the app
    // still boots (only the terminal pane degrades).
    try {
      await initializeForWeb(
        Uri.parse('assets/assets/libghostty-wasm32-freestanding.wasm'),
      );
    } catch (e) {
      debugPrint('flterm web init failed: $e');
    }
  } else {
    // Frameless desktop window with a custom title bar; keep the native macOS
    // traffic-light controls.
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1240, 800),
      minimumSize: Size(960, 640),
      center: true,
      backgroundColor: Color(0x00000000),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: ZmlLabApp()));
}
