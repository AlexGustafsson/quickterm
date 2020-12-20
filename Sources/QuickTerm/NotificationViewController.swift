import AppKit
import SwiftUI

import QuickTermShared

class NotificationViewController {
  private let window: NSWindow!
  private let sessionManager: TerminalSessionManager!

  init?(sessionManager: TerminalSessionManager) {
    self.sessionManager = sessionManager
    let contentView = ContentView(sessionManager: self.sessionManager)

    guard let mainScreen = NSScreen.main else {
      logger.error("Unable to find main screen")
      return nil
    }

    self.window = NSWindow(
      contentRect: NSRect(
        x: mainScreen.visibleFrame.maxX - 395,
        y: mainScreen.visibleFrame.minY,
        width: 395,
        height: mainScreen.visibleFrame.height
      ),
      // Toggling between these two lines are useful for debugging the UI
      styleMask: .borderless,
      // styleMask: .titled,
      backing: .buffered,
      defer: false
    )
    self.window.level = .floating
    self.window.tabbingMode = .disallowed
    self.window.contentView = NSHostingView(rootView: contentView)
    self.window.backgroundColor = .clear
  }

  public func show() {
    self.window.makeKeyAndOrderFront(nil)
  }

  public func hide() {
    self.window.orderOut(nil)
  }
}
