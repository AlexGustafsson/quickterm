import AppKit
import QuickTermShared
import SwiftUI

class InputViewController {
  private let commandHistoryManager: CommandHistoryManager
  private var inputView: InputView!
  private let window: BorderlessWindow!
  private var previousApp: NSRunningApplication? = nil

  typealias ExecuteCallback = (_ command: String) -> Void
  public var onExecuteCommand: ExecuteCallback = { _ in }

  init?() {
    guard let mainScreen = NSScreen.main else {
      logger.error("Unable to find main screen")
      return nil
    }

    let width = CGFloat(880)
    let height = CGFloat(250)

    let centerX = mainScreen.visibleFrame.minX + CGFloat((mainScreen.visibleFrame.width - width) / 2)
    let centerY = mainScreen.visibleFrame.minY + CGFloat((mainScreen.visibleFrame.height - height) / 2)

    self.window = BorderlessWindow(
      contentRect: NSRect(
        x: centerX,
        y: centerY,
        width: width,
        height: height
      ),
      // Toggling between these two lines are useful for debugging the UI
      styleMask: .borderless,
      // styleMask: .titled,
      backing: .buffered,
      defer: false
    )
    self.window.canMove = true
    self.window.level = .floating
    self.window.tabbingMode = .disallowed
    self.window.backgroundColor = .clear
    self.window.isOpaque = false

    let horizontalCenter = Guideline(x: centerX, y: centerY, threshold: CGFloat(10), orientation: .horizontal)
    let verticalCenter = Guideline(x: centerX, y: centerY, threshold: CGFloat(10), orientation: .vertical)
    self.window.guidelines.append(horizontalCenter)
    self.window.guidelines.append(verticalCenter)

    self.commandHistoryManager = CommandHistoryManager()
    self.inputView = InputView(commandHistoryManager: commandHistoryManager, onCommit: onCommit, onCancel: onCancel)
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

  func onCommit(command: String) {
    logger.debug("Commiting command '\(command, privacy: .public)'")
    if command.count > 0 {
      self.onExecuteCommand(command)
      self.commandHistoryManager.append(CommandHistoryItem(command))
    }
    self.hide()
  }

  func onCancel() {
    self.hide()
  }

  public func show() {
    DispatchQueue.main.async {
      self.previousApp = NSWorkspace.shared.runningApplications.first(where: { $0.isActive })
      self.window.makeKeyAndOrderFront(nil)
      NSApplication.shared.activate(ignoringOtherApps: true)
      logger.debug("Window can become key? \(self.window.canBecomeKey), \(self.window.canBecomeMain)")
      logger.debug("Window is key? \(self.window.isKeyWindow)")
    }
  }

  public func hide() {
    self.window.orderOut(nil)
    self.inputView.command = ""
    self.previousApp?.activate(options: .activateAllWindows)
    self.previousApp = nil
  }
}
