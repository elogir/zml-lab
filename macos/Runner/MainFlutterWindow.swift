import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Key events already dispatched once, to break a redispatch cycle between
  /// the Flutter engine and an embedded WKWebView:
  ///
  /// With the webview as first responder, WebKit delivers a keydown to the
  /// page asynchronously; when the page doesn't claim it, WebKit *re-sends
  /// the same NSEvent instance* through `[NSApp sendEvent:]`
  /// (WebViewImpl::doneWithKeyEvent) so the rest of the app gets a second
  /// chance at it. That re-sent event bubbles up to FlutterView, whose
  /// keyboard manager — also finding it unhandled — redispatches it down the
  /// responder chain, WebKit re-sends again, and the cycle spins forever
  /// (each side's own redispatch guard only covers its synchronous leg). One
  /// physical keypress became ~180k keydowns; a page that zooms while a key
  /// is held (xprof's trace viewer) zooms until the tab dies.
  ///
  /// Identity must be the event *instance* (===): WebKit re-sends the same
  /// object (WebViewImpl::doneWithKeyEvent passes the event straight to
  /// `[NSApp sendEvent:]`), while every genuine event — including
  /// auto-repeats — arrives as a fresh instance, so nothing real is ever
  /// dropped. Events are retained while in the buffer so a deallocated
  /// event's address can't be recycled into a false match.
  private var seenKeyEvents: [NSEvent] = []

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
      if seenKeyEvents.contains(where: { $0 === event }) {
        return // a re-sent echo, not a new press — drop it
      }
      seenKeyEvents.append(event)
      if seenKeyEvents.count > 16 {
        seenKeyEvents.removeFirst(seenKeyEvents.count - 16)
      }
    }
    super.sendEvent(event)
  }
}
