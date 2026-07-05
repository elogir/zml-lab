import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationWillFinishLaunching(_ notification: Notification) {
    // macOS's press-and-hold accent picker suppresses auto-repeat for letter
    // keys, which is wrong for a tool built around terminals (hold a key in a
    // shell, or w/s-zoom in xprof, and expect it to repeat). Opt this app out,
    // like other terminal apps do, so held keys repeat everywhere.
    UserDefaults.standard.register(defaults: ["ApplePressAndHoldEnabled": false])
    super.applicationWillFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
