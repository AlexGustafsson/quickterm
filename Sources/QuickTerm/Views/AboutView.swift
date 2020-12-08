import Foundation
import SwiftUI

struct AboutView: View {
  private let applicationName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
  private let applicationVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

  var body: some View {
    VStack(alignment: .center) {
      Text("⌘").font(.largeTitle)
      Text(applicationName).font(.headline)
      Text("App version: v\(applicationVersion)").font(.footnote)
      VStack {
        Text("\(applicationName) is Free Open Source Software.")
        Link("Contribute on GitHub", destination: URL(string: "https://github.com/AlexGustafsson/quickterm")!)
      }
      .font(.body).padding()
    }
    .padding()
  }
}
