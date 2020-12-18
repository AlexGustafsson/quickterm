import AppKit
import SwiftUI

import QuickTermShared

class InputWindowDelegate: NSWindowController, NSWindowDelegate {
  func windowDidResignKey(_ notification: Notification) {
    self.window?.close()
  }
}

class InputViewController {
  private let windowDelegate: InputWindowDelegate
  private let window: NSWindow!

  // TODO: make movable https://developer.apple.com/library/archive/samplecode/RoundTransparentWindow/Listings/Classes_CustomWindow_m.html#//apple_ref/doc/uid/DTS10000401-Classes_CustomWindow_m-DontLinkElementID_8
  // TODO: save location like Spotlight
  // https://stackoverflow.com/questions/46023769/how-to-show-a-window-without-stealing-focus-on-macos
  // https://stackoverflow.com/questions/15077471/show-window-without-activating-keep-application-below-it-active#comment112101726_15079362
  init?() {
    self.windowDelegate = InputWindowDelegate()
    let inputView = InputView()

    guard let mainScreen = NSScreen.main else {
      logger.error("Unable to find main screen")
      return nil
    }

    let width = CGFloat(1000)
    let height = CGFloat(150)

    self.window = BorderlessWindow(
      contentRect: NSRect(
        x: mainScreen.visibleFrame.minX + (mainScreen.visibleFrame.width - width) / 2,
        y: mainScreen.visibleFrame.minY + (mainScreen.visibleFrame.height - height) / 2,
        width: width,
        height: height
      ),
      // Toggling between these two lines are useful for debugging the UI
      styleMask: .borderless,
      // styleMask: .titled,
      backing: .buffered,
      defer: false
    )
    self.window.level = .floating
    self.window.delegate = self.windowDelegate
    self.window.tabbingMode = .disallowed
    self.window.contentView = NSHostingView(rootView: inputView)
    self.window.backgroundColor = .clear
    self.window.isOpaque = false
  }

  public func show() {
    self.window.makeFirstResponder(nil)
    self.window.makeKeyAndOrderFront(nil)
    self.window.orderFrontRegardless()
    NSApplication.shared.activate(ignoringOtherApps: true)
    logger.info("Window can become key? \(self.window.canBecomeKey), \(self.window.canBecomeMain)")
    logger.info("Window is key? \(self.window.isKeyWindow)")
  }

  public func hide() {
    self.window.close()
  }
}