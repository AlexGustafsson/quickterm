import AppKit

class BorderlessWindow: NSWindow {
  public var canMove: Bool = false
  private var initialLocation: NSPoint?

  override var canBecomeKey: Bool  { true }
  override var canBecomeMain: Bool { true }

  override func mouseDown(with event: NSEvent) {
    self.initialLocation = event.locationInWindow
  }

  override func mouseDragged(with event: NSEvent) {
    if !self.canMove {
      return
    }

    guard let mainScreen = NSScreen.main else {
      logger.error("Unable to find main screen")
      return
    }

    var newOrigin = self.frame.origin
    newOrigin.x += (event.locationInWindow.x - self.initialLocation!.x)
    newOrigin.y += (event.locationInWindow.y - self.initialLocation!.y)

    // Don't move under the menu bar
    if (newOrigin.y + self.frame.size.height) > mainScreen.visibleFrame.origin.y + mainScreen.visibleFrame.size.height {
      newOrigin.y = mainScreen.visibleFrame.origin.y + (mainScreen.visibleFrame.size.height - self.frame.size.height)
    }

    self.setFrameOrigin(newOrigin)
  }
}
