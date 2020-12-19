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
  // TODO: Handle "TAB completion" for files etc.
  // TODO: Handle potential completions as text behind input: https://stackoverflow.com/questions/6713391/can-bash-completion-be-invoked-programmatically
  init?() {
    self.windowDelegate = InputWindowDelegate()

    guard let mainScreen = NSScreen.main else {
      logger.error("Unable to find main screen")
      return nil
    }

    let width = CGFloat(880)
    let height = CGFloat(250)

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
    self.window.backgroundColor = .clear
    self.window.isOpaque = false

    let inputView = InputView().onExitCommand {
      self.hide()
    }
    self.window.contentView = NSHostingView(rootView: inputView)
  }

  public func show() {
    DispatchQueue.main.async {
      self.window.makeFirstResponder(nil)
      self.window.makeKeyAndOrderFront(nil)
      self.window.orderFrontRegardless()
      NSApplication.shared.activate(ignoringOtherApps: true)
      logger.info("Window can become key? \(self.window.canBecomeKey), \(self.window.canBecomeMain)")
      logger.info("Window is key? \(self.window.isKeyWindow)")
    }
  }

  public func hide() {
    self.window.orderOut(nil)
  }
}
