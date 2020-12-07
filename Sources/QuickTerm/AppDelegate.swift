import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
  var window: NSWindow!
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let sessionManager = TerminalSessionManager()
    let contentView = ContentView(sessionManager: sessionManager)

    guard let mainScreen = NSScreen.main else {
      assertionFailure()
      return
    }

    window = NSWindow(
      contentRect: NSRect(x: mainScreen.visibleFrame.width - 345, y: -100, width: 345, height: mainScreen.visibleFrame.height),
      styleMask: .borderless,
      // styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false
    )
    window.level = .floating
    window.tabbingMode = .disallowed
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(nil)
    window.isMovable = true
    window.backgroundColor = .clear

    sessionManager.append(TerminalSession("tail -f test.txt"))
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // TODO: stop all processes?
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
