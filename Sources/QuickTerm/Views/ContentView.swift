import SwiftUI

struct ContentView: View {
  @ObservedObject var sessionManager: TerminalSessionManager

  var body: some View {
    GeometryReader {
      geometry in
      VStack(alignment: .leading) {
        ForEach(sessionManager.items) {
          session in
          NotificationView(session: session)
        }
      }.frame(width: geometry.size.width, height: geometry.size.height) // Force same size as window
    }
  }
}
