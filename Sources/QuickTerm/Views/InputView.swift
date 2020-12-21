import SwiftUI

import Introspect

import QuickTermLibrary

class NSTextFieldActionProxy: NSObject, NSTextFieldDelegate {
  typealias EnterCallback = (_ command: String) -> ()
  public var onEnterCallback: EnterCallback = { _ in }

  typealias TabCallback = () -> ()
  public var onTabCallback: TabCallback = {}

  typealias EscapeCallback = () -> ()
  public var onEscapeCallback: EscapeCallback = {}

  typealias SelectAllCallback = () -> ()
  public var onSelectAllCallback: SelectAllCallback = {}

  typealias MoveUpCallback = () -> ()
  public var onMoveUpCallback: MoveUpCallback = {}

  typealias MoveDownCallback = () -> ()
  public var onMoveDownCallback: MoveDownCallback = {}

  weak var proxyDelegate: NSTextFieldDelegate?

  override func responds(to aSelector: Selector!) -> Bool {
    return super.responds(to: aSelector) || self.proxyDelegate?.responds(to: aSelector) == true
  }

  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    if self.proxyDelegate?.responds(to: aSelector) == true {
      return proxyDelegate
    } else {
      return super.forwardingTarget(for: aSelector)
    }
  }

  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
      self.onEnterCallback(textView.string)
      return true
    } else if (commandSelector == #selector(NSResponder.insertTab(_:))) {
      self.onTabCallback()
      return true
    } else if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
      self.onEscapeCallback()
      return true
    } else if commandSelector == NSSelectorFromString("noop:") {
      // TODO: This is likely not the correct way to do this,
      // but for now it seems to work.
      // The correct way likely includes identifying the correct event
      // from the event queue and then checking the flags to see if it
      // was actually "select all"
      self.onSelectAllCallback()
      return true
    } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
      self.onMoveUpCallback()
      return true
    } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
      self.onMoveDownCallback()
      return true
    }

    logger.debug("Passing selector: \(commandSelector, privacy: .public)")
    return self.proxyDelegate?.control?(control, textView: textView, doCommandBy: commandSelector) ?? false
  }

  // func controlTextDidChange(_ notification: Notification) {
  //   if let textField = notification.object as? NSTextField {
  //     self.text = textField.stringValue
  //     logger.debug("Got value1: \(self.text, privacy: .public)")
  //     logger.debug("Got value2: \(textField.stringValue, privacy: .public)")
  //   }
  // }
}

struct InputView: View {
  @State var command: String = ""

  public let actionProxy: NSTextFieldActionProxy! = NSTextFieldActionProxy()

  init() {
      self.actionProxy.onMoveUpCallback = self.previousHistoryItem
      self.actionProxy.onMoveDownCallback = self.nextHistoryItem
  }

  var body: some View {
    VStack(alignment: .center) {
      HStack(alignment: .center) {
        Text(">").font(.custom("FiraMono-Regular", size: 22)).opacity(0.6)
        TextField("", text: $command, onEditingChanged: onEditingChanged(_:))
          .font(.custom("FiraMono-Regular", size: 22))
          .background(Color.clear)
          .textFieldStyle(PlainTextFieldStyle())
          .introspectTextField {
            textField in
            // Custom key handling
            actionProxy.proxyDelegate = textField.delegate
            textField.delegate = actionProxy
            // Focus when view is shown
            textField.becomeFirstResponder()
            // Disable tabbing to the next view
            textField.nextKeyView = nil
            // Handle select all
            actionProxy.onSelectAllCallback = {
              textField.currentEditor()?.selectedRange = NSMakeRange(0, textField.stringValue.count)
            }
          }
      }
      .padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
      .frame(maxWidth: 680)
      .overlay(
        RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.2), lineWidth: 1)
      )
      .background(
        VisualEffectView(
          material: NSVisualEffectView.Material.popover,
          blendingMode: NSVisualEffectView.BlendingMode.behindWindow,
          cornerRadius: 10
        ).shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 25)
      )
    }
    .padding(100)
  }

  func onEditingChanged(_ changed: Bool) {
    logger.debug("Changed? \(changed, privacy: .public):  \(self.command, privacy: .public)")
  }

  func nextHistoryItem() {
    command = "history"
    logger.debug("Next history item")
  }

  func previousHistoryItem() {
    command = "previous history"
    logger.debug("Previous history item")
  }
}
