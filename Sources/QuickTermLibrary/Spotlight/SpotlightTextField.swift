import AppKit
import SwiftUI

// Awful hack to actually allow setting the font of the textfield
// unless this is done, the font is always cleared by the system
// no matter how it is set...
class ExplicitFontTextFieldCell: NSTextFieldCell {
  override var font: NSFont? {
    get {
      super.font
    }
    set {
      // Do nothing, use realFont instead
      if let font = NSFont(name: "FiraMono-Regular", size: 22) {
        super.font = font
      } else {}
    }
  }
}

// Awful hack to actually allow setting the font of the textfield
// unless this is done, the font is always cleared by the system
// no matter how it is set...
private class ExplicitFontTextField: NSTextField {
  private static let commandKey = NSEvent.ModifierFlags.command.rawValue
  private static let controlKey = NSEvent.ModifierFlags.control.rawValue
  private static let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue

  // The required coder init does not support this controller,
  // therefore make it mutable and nil by default
  private var controller: Spotlight?

  public convenience init(controller: Spotlight) {
    self.init()
    self.controller = controller
  }

  override class var cellClass: AnyClass? {
    get { ExplicitFontTextFieldCell.self }
    set {}
  }

  override var font: NSFont? {
    get {
      super.font
    }
    set {
      // Do nothing, use realFont instead
      if let font = NSFont(name: "FiraMono-Regular", size: 22) {
        super.font = font
      } else {}
    }
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.type == NSEvent.EventType.keyDown {
      let modifierFlags = event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
      let character = event.charactersIgnoringModifiers!
      if modifierFlags == ExplicitFontTextField.commandKey {
        switch character {
        case "x":
          // command + x (cut)
          if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
        case "c":
          // command + c (copy)
          if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
        case "v":
          // command + v (paste)
          if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
        case "z":
          // command + z (undo)
          if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) { return true }
        case "a":
          // command + a (select all)
          if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self) { return true }
        default:
          // Let the delegate decide what to do
          if self.controller?.delegate?.keyWithCommandPressed(character: character) ?? false { return true }
        }
      } else if modifierFlags == ExplicitFontTextField.commandShiftKey {
        if event.charactersIgnoringModifiers == "Z" {
          if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) { return true }
        } else {
          // Let the delegate decide what to do
          if self.controller?.delegate?.keyWithCommandAndShiftPressed(character: character) ?? false { return true }
        }
      } else if modifierFlags == ExplicitFontTextField.controlKey {
        if self.controller?.delegate?.keyWithControlPressed(character: character) ?? false { return true }
      }
    }
    return super.performKeyEquivalent(with: event)
  }
}

struct SpotlightTextField: NSViewRepresentable {
  private let placeholder: String
  private let controller: Spotlight
  @Binding var text: String

  @State var becomeFirstResponder: Bool = true

  init(
    _ placeholder: String,
    text: Binding<String>,
    controller: Spotlight
  ) {
    self.placeholder = placeholder
    self._text = text
    self.controller = controller
  }

  func makeNSView(context: Context) -> NSTextField {
    // Awful hack to actually allow setting the font of the textfield
    // unless this is done, the font is always cleared by the system
    // no matter how it is set...
    let textField = ExplicitFontTextField(controller: self.controller)
    textField.delegate = context.coordinator
    textField.isEditable = true
    textField.isSelectable = true
    textField.stringValue = self.text
    textField.placeholderString = self.placeholder
    textField.isBordered = false
    textField.backgroundColor = .clear
    textField.allowsEditingTextAttributes = true
    // Disable tabbing to the next view
    textField.nextKeyView = nil
    return textField
  }

  func updateNSView(_ textField: NSTextField, context _: Context) {
    textField.stringValue = self.text
    if self.becomeFirstResponder {
      DispatchQueue.main.async {
        // Focus when view is shown
        textField.becomeFirstResponder()
        // The above line will select all the text if an initial value was set,
        // clear this selection by moving the cursor to the end of the text
        textField.currentEditor()?.selectedRange = NSMakeRange(self.text.count, 0)
        self.becomeFirstResponder = false
      }
    }
    // TODO: Update font here instead?
    // this seems to be the right place to update the view
  }

  func makeCoordinator() -> SpotlightTextField.Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, NSTextFieldDelegate {
    private let parent: SpotlightTextField

    init(_ parent: SpotlightTextField) {
      self.parent = parent
    }

    func controlTextDidChange(_ notification: Notification) {
      // Handle the change of the controller's text - update the binding
      let textField = notification.object as! NSTextField
      self.parent.text = textField.stringValue
      self.parent.controller.delegate?.textChanged(text: self.parent.text)
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
      if commandSelector == #selector(NSResponder.insertNewline(_:)) {
        // Enter was clicked - commit the text
        self.parent.controller.commit()
        return true
      } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
        // Tab was clicked - let the delegate deside what to do
        self.parent.controller.tabPressed()
        return true
      } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
        // Escape was clicked - cancel the view
        self.parent.controller.cancel()
        return true
      } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
        // The up arrow was clicked - go to the previous item
        self.parent.controller.previousItem()
        return true
      } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
        // The down arrow was clicked - go to the next item
        self.parent.controller.nextItem()
        return true
      }

      return false
    }
  }
}
