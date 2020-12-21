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

  typealias CommitCallback = (_ text: String) -> ()
  public var onCommit: CommitCallback = { _ in }

  typealias CancelCallback = () -> ()
  public var onCancel: CancelCallback = {}

  @State var becomeFirstResponder: Bool = true

  init(_ placeholder: String, text: Binding<String>, onCommit: @escaping CommitCallback, onCancel: @escaping CancelCallback) {
    self.placeholder = placeholder
    self._text = text
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
        textField.currentEditor()?.selectedRange = NSMakeRange(textField.stringValue.count, textField.stringValue.count)
        self.becomeFirstResponder = false
      }
    }
  }

  func makeCoordinator() -> SpotlightTextField.Coordinator {
    return Coordinator(parent: self)
  }

  func onTab() {

  }

  func onPreviousInHistory() {
    self.text = "previous"
  }

  func onNextInHistory() {
    self.text = "next"
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
        textView.string = ""
        return true
      } else if (commandSelector == #selector(NSResponder.insertTab(_:))) {
        self.parent.onTab()
        return true
      } else if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
        textView.string = ""
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
