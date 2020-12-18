import AppKit

class BorderlessWindow: NSWindow {
  override var canBecomeKey: Bool {
    return true
  }

  override var canBecomeMain: Bool {
    return true
  }
}
