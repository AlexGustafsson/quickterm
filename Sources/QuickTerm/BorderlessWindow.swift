import AppKit

class BorderlessWindow: NSWindow {
  override var canBecomeKey: Bool  { true }
  override var canBecomeMain: Bool { true }
}
