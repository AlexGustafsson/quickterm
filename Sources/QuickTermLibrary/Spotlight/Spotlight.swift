import AppKit
import QuickTermShared
import SwiftUI

public class Spotlight: ObservableObject {
  @Published public var text = ""

  /// The window within which the Spotlight view will be rendered
  private(set) var window: SpotlightWindow

  private var previousApp: NSRunningApplication?

  public var delegate: SpotlightDelegate?

  public typealias CommitCallback = (String) -> Void
  private var onCommit: CommitCallback = { _ in }

  public typealias CancelCallback = () -> Void
  private var onCancel: CancelCallback = {}

  public init?() {
    guard let mainScreen = NSScreen.main else {
      logger.error("Unable to find main screen")
      return nil
    }

    let width = CGFloat(880)
    let height = CGFloat(250)

    let centerX = mainScreen.visibleFrame.minX + CGFloat((mainScreen.visibleFrame.width - width) / 2)
    let centerY = mainScreen.visibleFrame.minY + CGFloat((mainScreen.visibleFrame.height - height) / 2)

    self.window = SpotlightWindow(
      contentRect: NSRect(
        x: centerX,
        y: centerY,
        width: width,
        height: height
      )
    )

    let horizontalCenter = SpotlightWindow.Guideline(
      x: centerX,
      y: centerY,
      threshold: CGFloat(10),
      orientation: .horizontal
    )
    let verticalCenter = SpotlightWindow.Guideline(
      x: centerX,
      y: centerY,
      threshold: CGFloat(10),
      orientation: .vertical
    )
    self.window.guidelines.append(horizontalCenter)
    self.window.guidelines.append(verticalCenter)

    let view = SpotlightView(
      placeholder: "Enter command"
    ).environmentObject(self)
    self.window.contentView = NSHostingView(rootView: view)

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

  public func show(onCancel: CancelCallback? = nil, onCommit: @escaping CommitCallback) {
    self.delegate?.willShow()
    if onCancel != nil {
      self.onCancel = onCancel!
    }
    self.onCommit = onCommit
    DispatchQueue.main.async {
      self.previousApp = NSWorkspace.shared.runningApplications.first(where: { $0.isActive })
      self.window.makeKeyAndOrderFront(nil)
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
    self.delegate?.shown()
  }

  public func hide() {
    NotificationCenter.default.removeObserver(
      self,
      name: NSWindow.didResignKeyNotification,
      object: self.window
    )

    self.delegate?.willHide()
    self.window.orderOut(nil)
    // Activate the previous application
    self.previousApp?.activate(options: .activateAllWindows)
    self.previousApp = nil
    self.delegate?.hidden()
  }

  public func commit() {
    self.hide()
    self.onCommit(self.text)
    self.delegate?.commit()
  }

  public func cancel() {
    self.hide()
    self.onCancel()
    self.delegate?.cancel()
  }

  public func previousItem() {}

  public func nextItem() {}

  public func reset() {
    self.text = ""
  }

  public func clear() {
    self.text = ""
  }
}
