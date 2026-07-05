import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Identities of key events already dispatched once, to break a redispatch
  /// cycle between the Flutter engine and an embedded WKWebView:
  ///
  /// With the webview as first responder, WebKit delivers an unhandled
  /// keydown to the page and then bubbles it up the responder chain to
  /// FlutterView; the Flutter engine, seeing nobody claim it, *redispatches a
  /// copy* through `sendEvent` — where it reaches the webview again, WebKit
  /// re-bubbles it as what looks like a brand-new event (defeating the
  /// engine's own redispatch guard), and the cycle spins forever. One
  /// physical keypress became ~180k keydowns; a page that zooms while a key
  /// is held (xprof's trace viewer) zooms until the tab dies.
  ///
  /// A real key event never repeats with the same (timestamp, type, keyCode)
  /// — even auto-repeat gets fresh timestamps — so dropping exact repeats
  /// kills the loop without touching normal typing anywhere else.
  private var seenKeyEvents: [(TimeInterval, NSEvent.EventType, UInt16)] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  override func sendEvent(_ event: NSEvent) {
    if event.type == .keyDown || event.type == .keyUp {
      let identity = (event.timestamp, event.type, event.keyCode)
      if seenKeyEvents.contains(where: { $0 == identity }) {
        return // a redispatched echo, not a new press — drop it
      }
      seenKeyEvents.append(identity)
      if seenKeyEvents.count > 16 {
        seenKeyEvents.removeFirst(seenKeyEvents.count - 16)
      }
    }
    super.sendEvent(event)
  }
}
