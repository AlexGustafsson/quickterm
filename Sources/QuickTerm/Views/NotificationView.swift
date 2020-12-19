import SwiftUI

import QuickTermLibrary

struct NotificationView: View {
  @ObservedObject var session: TerminalSession

  var body: some View {
    VStack(alignment: .leading) {
      Text(session.configuration.command).font(.custom("Fira Mono", size: 11))
        .foregroundColor(session.hasFinished ? (session.wasSuccessful ? .green : .red) : .primary)
      ScrollView {
        Ansi.format(session.stdoutOutput).font(.custom("Fira Mono", size: 11)).frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
      }
    }
    .padding().frame(minWidth: 345, maxWidth: 345, minHeight: 70, maxHeight: 355, alignment: .topLeading)
    .overlay(
      RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.1), lineWidth: 1)
    )
    .background(
      VisualEffectView(
        material: NSVisualEffectView.Material.popover,
        blendingMode: NSVisualEffectView.BlendingMode.behindWindow,
        cornerRadius: 10.0
      ).shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
    )
  }
}
