import SwiftUI

import Introspect

import QuickTermLibrary

struct InputView: View {
  @State var command: String = ""

  var body: some View {
    VStack(alignment: .center) {
      HStack(alignment: .center) {
        Text(">").font(.custom("Fira Mono", size: 22)).foregroundColor(Color.black.opacity(0.5))
        TextField("Enter command", text: $command, onEditingChanged: onEditingChanged(_:), onCommit: onCommit)
          .font(.custom("Fira Mono", size: 22))
          .background(Color.clear)
          .textFieldStyle(PlainTextFieldStyle())
          .focusable(onFocusChange: onFocusChange)
          .introspectTextField {textField in textField.becomeFirstResponder()}
      }
      .padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
      .frame(maxWidth: 680)
      .overlay(
        RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.1), lineWidth: 1)
      )
      .background(
        VisualEffectView(
          material: NSVisualEffectView.Material.popover,
          blendingMode: NSVisualEffectView.BlendingMode.behindWindow,
          cornerRadius: 10
        )
      )
      .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 25)
    }
    .padding(100)
  }

  func onCommit() {
    logger.info("commit \(self.command)")
  }

  func onEditingChanged(_ changed: Bool) {
    logger.info("Changed? \(changed, privacy: .public):  \(self.command)")
  }

  func onFocusChange(_ focused: Bool) {
    logger.info("Focus changed: \(focused, privacy: .public)")
  }
}
