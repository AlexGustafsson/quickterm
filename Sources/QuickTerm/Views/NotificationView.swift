import QuickTermLibrary
import SwiftUI

struct CloseButtonStyle: ButtonStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .opacity(0.6).background(
        Circle()
          .fill(Color.clear)
          .frame(width: 22, height: 22)
          .background(
            VisualEffectView(
              material: NSVisualEffectView.Material.popover,
              blendingMode: NSVisualEffectView.BlendingMode.behindWindow,
              cornerRadius: 11
            )
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
          )
          .overlay(
            Circle()
              .stroke(Color.primary.opacity(0.2), lineWidth: 1)
          )
      )
  }
}

struct NotificationView: View {
  @ObservedObject var session: TerminalSession

  var body: some View {
    ZStack(alignment: .topLeading) {
      VStack(alignment: .leading) {
        Text("❯ ").font(.custom("FiraMono-Regular", size: 11))
          .foregroundColor(session.hasFinished ? (session.wasSuccessful ? .green : .red) : .primary)
          + Text(session.configuration.command).font(.custom("FiraMono-Regular", size: 11))
        ScrollView {
          outputText
        }
      }
      .padding().frame(minWidth: 345, maxWidth: 345, minHeight: 70, maxHeight: 355, alignment: .topLeading)
      .overlay(
        RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.2), lineWidth: 1)
      )
      .background(
        VisualEffectView(
          material: NSVisualEffectView.Material.popover,
          blendingMode: NSVisualEffectView.BlendingMode.behindWindow,
          cornerRadius: 10.0
        )
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
      )
      Button(action: session.terminate) {
        Text("x")
      }
      .buttonStyle(CloseButtonStyle())
      .offset(x: -3, y: -3)
    }
  }

  private var outputText: some View {
    let result = Ansi.format(session.output).font(.custom("FiraMono-Regular", size: 11))
      .frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
    // let result = Text(session.output).font(.custom("FiraMono-Regular", size: 11))
    //   .frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
    return Group {
      if session.configuration.animate {
        result.animation(.default)
      } else {
        result.animation(nil)
      }
    }
  }
}
