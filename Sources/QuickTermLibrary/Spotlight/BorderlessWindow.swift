import AppKit
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Library/Spotlight/BorderlessWindow")

public class SpotlightWindow: NSWindow {
  private var initialLocation: NSPoint?

  public override var canBecomeKey: Bool { true }
  public override var canBecomeMain: Bool { true }

  /// Whether or not the window can be moved
  public var canMove: Bool = false

  /// Guidelines where the window should stick
  public var guidelines: [Guideline] = []

  public convenience init(contentRect: NSRect) {
    self.init(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: false)

    self.canMove = true
    self.level = .floating
    self.tabbingMode = .disallowed
    self.backgroundColor = .clear
    self.isOpaque = false
  }

  public override func mouseDown(with event: NSEvent) {
    self.initialLocation = event.locationInWindow
  }

  public override func mouseDragged(with event: NSEvent) {
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

  public struct Guideline {
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
}
