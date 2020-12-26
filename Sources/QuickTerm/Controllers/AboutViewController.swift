import AppKit
import QuickTermShared
import SwiftUI

class AboutViewController {
  private let window: NSWindow!
  private let applicationName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""

  init() {
    let contentView = AboutView()
    self.window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 345, height: 245),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    self.window.isReleasedWhenClosed = false
    self.window.level = .popUpMenu
    self.window.contentView = NSHostingView(rootView: contentView)
    self.window.title = "About \(self.applicationName)"
    self.window.center()
  }

  public func show() {
    self.window.makeKeyAndOrderFront(nil)
  }

  public func hide() {
    self.window.orderOut(nil)
  }
}
