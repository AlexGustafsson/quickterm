import SwiftUI

struct ContentView: View {
  @ObservedObject var sessionManager: TerminalSessionManager

  var body: some View {
    GeometryReader {
      geometry in
      VStack(spacing: 10) {
        Spacer().frame(height: 5) // Top offset
        ForEach(sessionManager.items) {
          session in
          NotificationView(session: session)
        }
        Spacer() // Force items up towards the top
      }.transition(AnyTransition.slide).animation(.default).frame(width: geometry.size.width, height: geometry.size.height) // Force same size as window
    }
  }
}
