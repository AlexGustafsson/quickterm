import SwiftUI

import Introspect

import QuickTermLibrary

struct InputView: View {
  @State var command: String = ""

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .center) {
        Text(">").font(.custom("Fira Mono", size: 16)).padding()
        TextField("Enter command", text: $command, onEditingChanged: onEditingChanged(_:), onCommit: onCommit)
          .font(.custom("Fira Mono", size: 16))
          .background(Color.clear)
          .textFieldStyle(PlainTextFieldStyle())
          .focusable()
          .introspectTextField {textField in textField.becomeFirstResponder()}
      }
      .overlay(
        RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)
      )
      .background(
        VisualEffectView(
          material: NSVisualEffectView.Material.fullScreenUI,
          blendingMode: NSVisualEffectView.BlendingMode.behindWindow,
          cornerRadius: 10
        )
      )
      .shadow(color: Color.black.opacity(0.8), radius: 15, x: 0, y: 25)
    }
    .padding(100)
  }

  func onCommit() {
    print("commit")
  }

  func onEditingChanged(_ changed: Bool) {
    print(changed)
  }
}
