import SwiftUI

// https://stackoverflow.com/a/61458115
struct VisualEffectView: NSViewRepresentable {
  var material: NSVisualEffectView.Material
  var blendingMode: NSVisualEffectView.BlendingMode
  var cornerRadius = CGFloat(0)

  func makeNSView(context _: Context) -> NSVisualEffectView {
    let visualEffectView = NSVisualEffectView()
    visualEffectView.material = self.material
    visualEffectView.blendingMode = self.blendingMode
    visualEffectView.state = NSVisualEffectView.State.active
    visualEffectView.isEmphasized = true
    visualEffectView.wantsLayer = true
    return visualEffectView
  }

  func updateNSView(_ visualEffectView: NSVisualEffectView, context _: Context) {
    visualEffectView.material = self.material
    visualEffectView.blendingMode = self.blendingMode
    visualEffectView.layer?.cornerRadius = self.cornerRadius
  }
}
