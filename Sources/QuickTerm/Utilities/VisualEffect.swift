import SwiftUI

// https://stackoverflow.com/a/61458115
struct VisualEffectView: NSViewRepresentable {
  var material: NSVisualEffectView.Material
  var blendingMode: NSVisualEffectView.BlendingMode
  var cornerRadius: CGFloat = CGFloat(0)

  func makeNSView(context: Context) -> NSVisualEffectView {
    let visualEffectView = NSVisualEffectView()
    visualEffectView.material = material
    visualEffectView.blendingMode = blendingMode
    visualEffectView.state = NSVisualEffectView.State.active
    visualEffectView.isEmphasized = true
    visualEffectView.wantsLayer = true
    return visualEffectView
  }

  func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
    visualEffectView.material = material
    visualEffectView.blendingMode = blendingMode
    visualEffectView.layer?.cornerRadius = cornerRadius
  }
}
