import SwiftUI
import Foundation

struct AboutView: View {
  var applicationName = ProcessInfo.processInfo.processName

  var body: some View {
    VStack(alignment: .center) {
      Text("⌘")
        .font(.largeTitle)
      Text(applicationName)
        .font(.headline)
      Text("App version: v0.1.0")
        .font(.footnote)
      HStack(spacing: 0) {
        Text("Open source. ")
        Link("Contribute on GitHub", destination: URL(string: "https://github.com/AlexGustafsson/quickterm")!)
      }.font(.body).padding()
    }.padding()
  }
}
