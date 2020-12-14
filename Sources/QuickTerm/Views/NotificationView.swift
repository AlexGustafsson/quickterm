import SwiftUI

import QuickTermLibrary

struct NotificationView: View {
  @ObservedObject var session: TerminalSession

  var body: some View {
    VStack(alignment: .leading) {
      Text(session.configuration.command).font(.custom("Fira Mono", size: 11)).foregroundColor(session.hasFinished ? (session.wasSuccessful ? .green : .red) : .primary)

      ScrollView {
        Ansi.format(session.stdoutOutput).font(.custom("Fira Mono", size: 11)).frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
      }
    }
    .padding().frame(minWidth: 345, maxWidth: 345, minHeight: 200, maxHeight: 355, alignment: .topLeading)
    .background(
      VisualEffectView(
        material: NSVisualEffectView.Material.fullScreenUI,
        blendingMode: NSVisualEffectView.BlendingMode.behindWindow,
        cornerRadius: 10.0
      )
    )
  }
}
