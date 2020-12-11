import SwiftUI

struct ContentView: View {
  @ObservedObject var sessionManager: TerminalSessionManager

  var body: some View {
    VStack(alignment: .leading) { ForEach(sessionManager.items) { session in NotificationView(session: session) } }
  }
}
