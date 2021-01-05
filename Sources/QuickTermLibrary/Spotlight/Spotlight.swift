import AppKit
import QuickTermShared
import SwiftUI

public class Spotlight: ObservableObject {
  @Published public var text = ""
  @Published private(set) var itemCount: Int = 0
  @Published private(set) var items: [SpotlightItem] = []
  @Published private(set) var sections: [SpotlightItemSection] = []
  @Published private(set) var selectedItem: Int? = nil

  private var itemsBySection: [String: [SpotlightItem]] = [:]

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
    if let selectedItem = self.selectedItem {
      self.completeText()
    }
    self.onCommit(self.text)
    self.delegate?.commit()
  }

  public func cancel() {
    self.hide()
    self.onCancel()
    self.delegate?.cancel()
  }

  public func reset() {
    self.text = ""
  }

  public func clear() {
    self.text = ""
  }

  private func updateItems() {
    var itemCount = 0
    var sections: [SpotlightItemSection] = []
    var index = 0
    for sectionHeader in self.itemsBySection.keys {
      if let items = self.itemsBySection[sectionHeader] {
        let section = SpotlightItemSection(
          title: sectionHeader == "" ? nil : sectionHeader,
          items: items
        )
        itemCount += items.count
        sections.append(section)
        for item in items {
          if let selectedItem = self.selectedItem {
            if index == selectedItem {
              item.selected = true
            } else {
              item.selected = false
            }
          }
          index += 1
        }
      }
    }
    self.objectWillChange.send()
    self.itemCount = itemCount
    self.sections = sections
  }

  public func addDetailItem(text: String, details: [String] = [], textToComplete: String, section: String = "") {
    let detail = details.count > 0 ? " ― \(details.joined(separator: " • "))" : ""
    let item = SpotlightItem(text: text, detail: detail, textToComplete: textToComplete)
    self.addItem(item, section: section)
  }

  public func addDetailItem(text: String, details: [String] = [], textToInsert: String, section: String = "") {
    let detail = details.count > 0 ? " ― \(details.joined(separator: " • "))" : ""
    let item = SpotlightItem(text: text, detail: detail, textToInsert: textToInsert)
    self.addItem(item, section: section)
  }

  public func addCompletionItem(text: String, textToComplete: String, section: String = "") {
    let item = SpotlightItem(text: text, detail: textToComplete, textToComplete: textToComplete)
    self.addItem(item, section: section)
  }

  public func addItem(_ item: SpotlightItem, section: String = "") {
    if self.itemsBySection[section] == nil {
      self.itemsBySection[section] = []
    }
    self.itemsBySection[section]?.append(item)
    self.items.append(item)
    self.updateItems()
  }

  public func clearItems() {
    self.itemsBySection = [:]
    self.items = []
    self.updateItems()
  }

  public func nextItem() {
    if let selectedItem = self.selectedItem {
      self.selectedItem = (selectedItem + 1) % self.itemCount
    } else {
      self.selectedItem = 0
    }
    self.updateItems()
  }

  public func previousItem() {
    if let selectedItem = self.selectedItem {
      self.selectedItem = selectedItem == 0 ? self.itemCount - 1 : selectedItem - 1
    } else {
      self.selectedItem = 0
    }
    self.updateItems()
  }

  public func clearSelection() {
    self.selectedItem = nil
  }

  public func completeText() {
    if let selectedItem = self.selectedItem {
      let item = self.items[selectedItem]
      if let textToComplete = item.textToComplete {
        self.text += textToComplete
      } else if let textToInsert = item.textToInsert {
        self.text = textToInsert
      }
      self.delegate?.textChanged(text: self.text)
    }
  }

  public func tabPressed() {
    if let selectedItem = self.selectedItem {
      self.completeText()
    } else {
      self.delegate?.tabPressed()
    }
  }
}
