import AppKit
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/Utilities/BorderlessWindow")

struct Guideline {
  public let x: CGFloat
  public let y: CGFloat
  public let threshold: CGFloat
  public let orientation: Orientation

  public init(x: CGFloat, y: CGFloat, threshold: CGFloat, orientation: Orientation) {
    self.x = x
    self.y = y
    self.threshold = threshold
    self.orientation = orientation
  }

  public enum Orientation {
    case horizontal
    case vertical
  }

  public func snap(_ point: inout CGPoint) {
    if self.orientation == .horizontal, abs(point.y - self.y) <= self.threshold {
      point.y = self.y
    }

    if self.orientation == .vertical, abs(point.x - self.x) <= self.threshold {
      point.x = self.x
    }
  }
}

class BorderlessWindow: NSWindow {
  public var canMove: Bool = false
  private var initialLocation: NSPoint?

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  public var guidelines: [Guideline] = []

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

    for guideline in self.guidelines {
      guideline.snap(&newOrigin)
    }

    self.setFrameOrigin(newOrigin)
  }
}
