import 'package:flterm/flterm.dart' show initializeForWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'dart:async';

import 'app.dart';
import 'core/bootstrap.dart';
import 'core/execution/job_executor.dart';
import 'core/logging/app_log.dart';
import 'features/settings/application/settings_controller.dart';
import 'repositories/machine_repository.dart';

Future<void> main() async {
  // Diagnostic log to /tmp/zml_lab.log so a crash leaves a trail even for the
  // double-clicked release app (whose stdout goes nowhere). Set up first, and
  // run everything inside a guarded zone so uncaught async errors are caught.
  AppLog.init();
  final prevDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) AppLog.write(message);
    prevDebugPrint(message, wrapWidth: wrapWidth);
  };
  FlutterError.onError = (details) {
    AppLog.error(
      details.exception,
      details.stack,
      context: details.context?.toString() ?? 'flutter',
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error(error, stack, context: 'platform');
    return false; // logged, but don't swallow — keep default behaviour
  };

  runZonedGuarded(_run, (error, stack) => AppLog.error(error, stack, context: 'zone'));
}

Future<void> _run() async {
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

  // Own the container so we can seed the local machine and load settings
  // before the first frame (and so the same instance backs the whole app).
  final container = ProviderContainer();
  try {
    // Before the first frame so the persisted theme doesn't flash.
    await container.read(settingsControllerProvider.notifier).load();
  } catch (e) {
    debugPrint('settings load failed: $e');
  }
  try {
    await ensureLocalMachine(container.read(machineRepositoryProvider));
  } catch (e) {
    debugPrint('ensureLocalMachine failed: $e');
  }
  AppLog.write('boot ok — starting UI');

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
      AppLog.write('window close — stopping jobs and exiting');
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
