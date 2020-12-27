import QuickTermLibrary
import SwiftUI

struct InputView: View {
  @State var command: String = ""
  @ObservedObject var commandHistoryManager: CommandHistoryManager

  typealias CommitCallback = (_ text: String) -> Void
  var onCommit: CommitCallback = { _ in }

  typealias CancelCallback = () -> Void
  var onCancel: CancelCallback = {}

  init(
    commandHistoryManager: CommandHistoryManager,
    onCommit: @escaping CommitCallback,
    onCancel: @escaping CancelCallback
  ) {
    self.commandHistoryManager = commandHistoryManager
    self.onCommit = onCommit
    self.onCancel = onCancel
  }

  var body: some View {
    VStack(alignment: .center) {
      HStack(alignment: .center) {
        Text("❯").font(.custom("FiraMono-Regular", size: 22)).opacity(0.6)
        SpotlightTextField(
          "Enter command",
          text: $command,
          commandHistoryManager: commandHistoryManager,
          onCommit: onCommit,
          onCancel: onCancel
        )
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
        )
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 25)
      )
    }
    .padding(100)
  }
}
