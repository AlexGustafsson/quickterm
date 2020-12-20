import AppKit
import SwiftUI

import QuickTermShared

class InputViewController {
  private let inputView: InputView!
  private let window: NSWindow!

  typealias ExecuteCallback = (_ command: String) -> ()
  public var onExecuteCommand: ExecuteCallback = { _ in }

  // TODO: make movable https://developer.apple.com/library/archive/samplecode/RoundTransparentWindow/Listings/Classes_CustomWindow_m.html#//apple_ref/doc/uid/DTS10000401-Classes_CustomWindow_m-DontLinkElementID_8
  // TODO: save location like Spotlight
  // https://stackoverflow.com/questions/46023769/how-to-show-a-window-without-stealing-focus-on-macos
  // https://stackoverflow.com/questions/15077471/show-window-without-activating-keep-application-below-it-active#comment112101726_15079362
  // TODO: Handle "TAB completion" for files etc.
  // TODO: Handle potential completions as text behind input: https://stackoverflow.com/questions/6713391/can-bash-completion-be-invoked-programmatically
  init?() {
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
    self.window.tabbingMode = .disallowed
    self.window.backgroundColor = .clear
    self.window.isOpaque = false

    self.inputView = InputView()
    self.inputView.actionProxy.onEnterCallback = {
      command in
      logger.debug("Commiting command '\(command, privacy: .public)'")
      if (command.count > 0) {
        self.onExecuteCommand(command)
      }
      self.hide()
    }
    self.inputView.actionProxy.onEscapeCallback = {
      self.hide()
    }
    self.window.contentView = NSHostingView(rootView: self.inputView)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onWindowLostFocus),
      name: NSWindow.didResignKeyNotification,
      object: self.window
    )
  }

  @objc func onWindowLostFocus() {
    self.hide()
  }

  public func show() {
    DispatchQueue.main.async {
      self.window.makeKeyAndOrderFront(nil)
      NSApplication.shared.activate(ignoringOtherApps: true)
      logger.debug("Window can become key? \(self.window.canBecomeKey), \(self.window.canBecomeMain)")
      logger.debug("Window is key? \(self.window.isKeyWindow)")
    }
  }

  public func hide() {
    self.window.orderOut(nil)
    self.inputView.command = ""
  }
}
