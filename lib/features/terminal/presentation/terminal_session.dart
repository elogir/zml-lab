// One live terminal (flterm controller + PTY on native, stub on web).
// The platform-specific implementation is selected at compile time.
export 'terminal_session_web.dart'
    if (dart.library.io) 'terminal_session_native.dart';
