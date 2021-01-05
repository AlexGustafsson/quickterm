import AppKit
import QuickTermLibrary
import QuickTermShared
import SwiftUI

class CommandSpotlightDelegate: SpotlightDelegate {
  private let spotlight: Spotlight

  init(_ spotlight: Spotlight) {
    self.spotlight = spotlight
  }

  func willShow() {
    logger.debug("Showing spotlight view")
  }

  func shown() {
    logger.debug("Showed spotlight view")
  }

  func willHide() {
    logger.debug("Hiding spotlight view")
  }

  func hidden() {
    logger.debug("Hid spotlight view")
  }

  func textChanged(text: String) {
    logger.debug("Text changed: \(text, privacy: .public)")
    if text == "he" {
      self.spotlight.clearItems()
      self.spotlight.addCompletionItem(text: "he", completion: "llo world")
      self.spotlight.addCompletionItem(text: "He", completion: "llo, World!")
      self.spotlight.addDetailItem(
        text: "echo \"hello, world!\"",
        completion: "echo \"hello, world!\"",
        section: "History"
      )
      self.spotlight.addDetailItem(text: "hello world", completion: "echo \"hello, world!\"", section: "History")
    } else {
      self.spotlight.clearItems()
      self.spotlight.clearSelection()
    }
  }

  func tabClicked() {
    logger.debug("Tab clicked")
  }

  func keyWithCommandPressed(character: String) -> Bool {
    logger.debug("Pressed command+\(character, privacy: .public)")
    if character == "k" {
      // Clear any entered text, like command + k in Terminal
      self.spotlight.clear()
    }
    return false
  }

  func keyWithControlPressed(character: String) -> Bool {
    logger.debug("Pressed control+\(character, privacy: .public)")
    if character == "c" {
      // Clear any entered text, like control + c in Terminal
      self.spotlight.reset()
    }
    return false
  }

  func keyWithCommandAndShiftPressed(character: String) -> Bool {
    logger.debug("Pressed command+shift+\(character, privacy: .public)")
    return false
  }

  func commit() {
    logger.debug("Committed")
  }

  func cancel() {
    logger.debug("Canceled")
  }
}

class InputViewController {
  typealias ExecuteCallback = (_ command: String) -> Void
  public var onExecuteCommand: ExecuteCallback = { _ in }

  public func show() {
    // TODO: Only allow one to be shown?
    // if the hotkey is pressed when it's already shown,
    // hide it instead?
    if let spotlight = Spotlight() {
      let delegate = CommandSpotlightDelegate(spotlight)
      spotlight.delegate = delegate
      spotlight.show {
        command in
        self.onExecuteCommand(command)
      }
    }
  }
}
