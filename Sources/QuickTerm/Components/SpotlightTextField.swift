import AppKit
import SwiftUI

// Awful hack to actually allow setting the font of the textfield
// unless this is done, the font is always cleared by the system
// no matter how it is set...
class ExplicitFontTextFieldCell: NSTextFieldCell {
  override var font: NSFont? {
    get {
      return super.font
    }
    set {
      // Do nothing, use realFont instead
      if let font = NSFont(name: "FiraMono-Regular", size: 22) {
        super.font = font
        logger.debug("Loaded font")
      } else {
        logger.error("Unable to load font")
      }
    }
  }
}

// Awful hack to actually allow setting the font of the textfield
// unless this is done, the font is always cleared by the system
// no matter how it is set...
class ExplicitFontTextField: NSTextField {
  override class var cellClass: AnyClass? {
    get { ExplicitFontTextFieldCell.self }
    set {}
  }

  override var font: NSFont? {
    get {
      return super.font
    }
    set {
      // Do nothing, use realFont instead
      if let font = NSFont(name: "FiraMono-Regular", size: 22) {
        super.font = font
        logger.debug("Loaded font")
      } else {
        logger.error("Unable to load font")
      }
    }
  }
}

struct SpotlightTextField: NSViewRepresentable {
  let placeholder: String
  @Binding var text: String
  @State var textField: NSTextField? = nil
  @ObservedObject var commandHistoryManager: CommandHistoryManager

  @State var historyIndex: Int = -1

  typealias CommitCallback = (_ text: String) -> ()
  public var onCommit: CommitCallback = { _ in }

  typealias CancelCallback = () -> ()
  public var onCancel: CancelCallback = {}

  @State var becomeFirstResponder: Bool = true

  init(_ placeholder: String, text: Binding<String>, commandHistoryManager: CommandHistoryManager, onCommit: @escaping CommitCallback, onCancel: @escaping CancelCallback) {
    self.placeholder = placeholder
    self._text = text
    self.commandHistoryManager = commandHistoryManager
    self.onCommit = onCommit
    self.onCancel = onCancel
  }

  func makeNSView(context: Context) -> NSTextField {
    // Awful hack to actually allow setting the font of the textfield
    // unless this is done, the font is always cleared by the system
    // no matter how it is set...
    let textField = ExplicitFontTextField()
    textField.delegate = context.coordinator
    textField.isEditable = true
    textField.isSelectable = true
    textField.stringValue = text
    textField.placeholderString = self.placeholder
    textField.isBordered = false
    textField.backgroundColor = .clear
    textField.allowsEditingTextAttributes = true
    // Disable tabbing to the next view
    textField.nextKeyView = nil
    self.textField = textField
    return textField
  }

  func updateNSView(_ textField: NSTextField, context: Context) {
    textField.stringValue = self.text
    if self.becomeFirstResponder {
      DispatchQueue.main.async {
        // Focus when view is shown
        textField.becomeFirstResponder()
        // The above line will select all the text if an initial value was set,
        // clear this selection by moving the cursor to the end of the text
        textField.currentEditor()?.selectedRange = NSMakeRange(self.text.count, 0)
        self.becomeFirstResponder = false
        logger.debug("Became first responder")
      }
    }
  }

  func makeCoordinator() -> SpotlightTextField.Coordinator {
    return Coordinator(parent: self)
  }

  func onTab() {

  }

  func onPreviousInHistory() {
    if self.historyIndex >= self.commandHistoryManager.items.count - 1 {
      // Do nothing
    } else {
      self.historyIndex += 1
      self.text = self.commandHistoryManager.items[self.commandHistoryManager.items.count - 1 - self.historyIndex].command
      if let textField = self.textField {
        textField.currentEditor()?.selectedRange = NSMakeRange(self.text.count, 0)
      }
    }
  }

  func onNextInHistory() {
    if self.historyIndex == -1 {
      // Do nothing
    } else if self.historyIndex == 0 {
      self.historyIndex = -1
      self.text = ""
    } else {
      self.historyIndex -= 1
      self.text = self.commandHistoryManager.items[self.commandHistoryManager.items.count - 1 - self.historyIndex].command
      if let textField = self.textField {
        textField.currentEditor()?.selectedRange = NSMakeRange(self.text.count, 0)
      }
    }
  }

  class Coordinator: NSObject, NSTextFieldDelegate {
    var parent: SpotlightTextField

    init(parent: SpotlightTextField) {
      self.parent = parent
    }

    func controlTextDidChange(_ notification: Notification) {
      let textField = notification.object as! NSTextField
      self.parent.text = textField.stringValue
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
      if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
        self.parent.onCommit(textView.string)
        self.parent.text = ""
        self.parent.historyIndex = -1
        return true
      } else if (commandSelector == #selector(NSResponder.insertTab(_:))) {
        self.parent.onTab()
        return true
      } else if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
        self.parent.text = ""
        self.parent.historyIndex = -1
        self.parent.onCancel()
        return true
      } else if commandSelector == NSSelectorFromString("noop:") {
        // TODO: This is likely not the correct way to do this,
        // but for now it seems to work.
        // The correct way likely includes identifying the correct event
        // from the event queue and then checking the flags to see if it
        // was actually "select all"
        textView.selectedRange = NSMakeRange(0, textView.string.count)
        return true
      } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
        self.parent.onPreviousInHistory()
        return true
      } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
        self.parent.onNextInHistory()
        return true
      }

      logger.debug("Passing selector: \(commandSelector, privacy: .public)")
      return false
    }
  }
}
