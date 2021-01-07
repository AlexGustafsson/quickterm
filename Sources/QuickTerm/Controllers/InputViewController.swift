import AppKit
import QuickTermLibrary
import QuickTermShared
import SwiftUI
import UniformTypeIdentifiers

struct HistoryItem {
  let command: String
  let executionTime: Date
}

class CommandSpotlightDelegate: SpotlightDelegate {
  private let spotlight: Spotlight
  private let history: [HistoryItem]

  init(_ spotlight: Spotlight, history: [HistoryItem]) {
    self.spotlight = spotlight
    self.history = history
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
      self.spotlight.clearSection("")
      self.spotlight.addCompletionItem(text: "he", textToComplete: "llo world")
      self.spotlight.addCompletionItem(text: "He", textToComplete: "llo, World!")
    } else {
      self.spotlight.clearSection("")
      self.spotlight.clearSection("History")
    }

    if text == "" {
      self.spotlight.clearItems()
    }
  }

  func tabPressed() {
    logger.debug("Tab pressed")

    if !self.spotlight.hasSection("History") {
      self.renderHistory()
    }

    self.spotlight.clearSection("Files")
    let workingDirectory = Config.current.commandConfiguration.workingDirectory ?? FileManager.default
      .currentDirectoryPath
    do {
      let basenames = try FileManager.default.contentsOfDirectory(atPath: workingDirectory)
      for basename in basenames {
        var path = URL(fileURLWithPath: workingDirectory)
        path.appendPathComponent(basename)
        var details: [String] = []

        let attributes = try path
          .resourceValues(
            forKeys: Set([
              .fileSizeKey,
              .contentModificationDateKey,
              .isRegularFileKey,
              .isSymbolicLinkKey,
              .isExecutableKey,
              .isDirectoryKey,
            ])
          )
        if attributes.isRegularFile ?? false {
          details.append("File")
          if attributes.isExecutable ?? false {
            details.append("Executable")
          }

          if let fileSize = attributes.fileSize {
            let formattedFileSize = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            details.append(formattedFileSize)
          }
        } else if attributes.isSymbolicLink ?? false {
          details.append("Link")
        } else if attributes.isDirectory ?? false {
          details.append("Directory")
        }

        if let modificationDate = attributes.contentModificationDate {
          let dateFormatter = DateFormatter()
          dateFormatter.dateStyle = .medium
          dateFormatter.timeStyle = .none
          dateFormatter.locale = Locale.current

          details.append(dateFormatter.string(from: modificationDate))
        }

        self.spotlight.addDetailItem(text: basename, details: details, textToComplete: basename, section: "Files")
      }
    } catch {
      logger.error("Unable to complete file paths: \(error.localizedDescription, privacy: .public)")
    }
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

  func commit(text _: String) {
    logger.debug("Commited")
  }

  func cancel() {
    logger.debug("Canceled")
  }

  private func renderHistory() {
    for i in stride(from: self.history.count - 1, through: 0, by: -1) {
      let item = self.history[i]
      var details: [String] = []

      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .medium
      dateFormatter.timeStyle = .short
      dateFormatter.locale = Locale.current

      details.append(dateFormatter.string(from: item.executionTime))
      self.spotlight.addDetailItem(text: item.command, details: details, textToInsert: item.command, section: "History")
    }
  }

  func upPressed() {
    logger.debug("Pressed down")
    if !self.spotlight.hasSection("History") {
      self.renderHistory()
    }
  }

  func downPressed() {
    logger.debug("Pressed down")
    if !self.spotlight.hasSection("History") {
      self.renderHistory()
    }
  }
}

class InputViewController {
  typealias ExecuteCallback = (_ command: String) -> Void
  public var onExecuteCommand: ExecuteCallback = { _ in }

  private var history: [HistoryItem] = []

  public func show() {
    // TODO: Only allow one to be shown?
    // if the hotkey is pressed when it's already shown,
    // hide it instead?
    if let spotlight = Spotlight() {
      let delegate = CommandSpotlightDelegate(spotlight, history: self.history)
      spotlight.delegate = delegate
      spotlight.show {
        text in
        self.onExecuteCommand(text)
        self.history.append(HistoryItem(command: text, executionTime: Date()))
      }
    }
  }
}
