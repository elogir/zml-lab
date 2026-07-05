import 'package:flterm/flterm.dart' show initializeForWeb;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'dart:async';

import 'app.dart';
import 'core/bootstrap.dart';
import 'core/execution/job_executor.dart';
import 'repositories/machine_repository.dart';

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

  // Own the container so we can seed the local machine before the first frame
  // (and so the same instance backs the whole app).
  final container = ProviderContainer();
  try {
    await ensureLocalMachine(container.read(machineRepositoryProvider));
  } catch (e) {
    debugPrint('ensureLocalMachine failed: $e');
  }
  // Any job the DB still marks running died with the previous app session —
  // record them as stopped.
  unawaited(container.read(jobExecutorProvider).markStaleStopped());

  // Kill running jobs when the window closes so nothing is left behind (a job's
  // server survives a bare PTY-close, so we stop it explicitly).
  if (!kIsWeb) {
    await windowManager.setPreventClose(true);
    windowManager.addListener(_ShutdownHandler(container));
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ZmlLabApp(),
    ),
  );
}

/// Stops all running jobs before letting the window close.
class _ShutdownHandler extends WindowListener {
  _ShutdownHandler(this._container);

  final ProviderContainer _container;

  @override
  void onWindowClose() {
    () async {
      try {
        await _container.read(jobExecutorProvider).stopAll();
      } catch (e) {
        debugPrint('stopAll on close failed: $e');
      }
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
    }();
  }
}
