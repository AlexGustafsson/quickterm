import AppKit
import SwiftUI

import QuickTermShared

class NotificationHostingView : NSHostingView<ContentView> {
  typealias FocusChangedCallback = (Bool) -> ()
	var onFocusChanged: FocusChangedCallback = { _ in }

  private var trackingArea: NSTrackingArea    = NSTrackingArea()

  override func viewWillMove(toWindow newWindow: NSWindow?) {
    // Setup a new tracking area when the view is added to the window.
     trackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
     self.addTrackingArea(trackingArea)
  }

  override func updateTrackingAreas() {
    self.removeTrackingArea(trackingArea)

    trackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
    self.addTrackingArea(trackingArea)
  }

  override func mouseEntered(with event: NSEvent) {
    self.onFocusChanged(true)
 }

  override func mouseExited(with event: NSEvent) {
    self.onFocusChanged(false)
  }
}

class NotificationViewController {
  private var contentView: ContentView!
  private var window: NSWindow!
  private var sessionManager: TerminalSessionManager!

  init?(sessionManager: TerminalSessionManager) {
    self.sessionManager = sessionManager
    self.contentView = ContentView(sessionManager: self.sessionManager)

    guard let mainScreen = NSScreen.main else {
      logger.error("Unable to find main screen")
      return nil
    }

    let contentRect = NSRect(
      x: mainScreen.visibleFrame.maxX - 395,
      y: mainScreen.visibleFrame.minY,
      width: 395,
      height: mainScreen.visibleFrame.height
    )

    var hostingView = NotificationHostingView(rootView: contentView)
    hostingView.onFocusChanged = {
      focus in
      if focus {
        self.sessionManager.pauseRemoval()
      } else {
        self.sessionManager.resumeRemoval()
      }
    }

    self.window = NSWindow(
      contentRect: contentRect,
      // Toggling between these two lines are useful for debugging the UI
      styleMask: .borderless,
      // styleMask: .titled,
      backing: .buffered,
      defer: false
    )
    self.window.level = .floating
    self.window.tabbingMode = .disallowed
    self.window.contentView = hostingView
    self.window.backgroundColor = .clear
  }

  public func show() {
    self.window.makeKeyAndOrderFront(nil)
  }

  public func hide() {
    self.window.orderOut(nil)
  }
}
