import SwiftUI

struct ContentView: View {
  @ObservedObject var sessionManager: TerminalSessionManager

  var body: some View {
    GeometryReader {
      geometry in
      VStack(spacing: 10) {
        ForEach(sessionManager.sessions, id: \.id) {
          session in
          Group {
            NotificationView(session: session)
          }
        }
        Spacer() // Force items up towards the top
      }
      .padding(.init(top: 15, leading: 15, bottom: 73, trailing: 5)).transition(AnyTransition.slide).animation(.default)
      .frame(width: geometry.size.width, height: geometry.size.height) // Force same size as window
    }
  }
}
