import SwiftUI

public struct SpotlightView: View {
  public let placeholder: String
  @EnvironmentObject var controller: Spotlight

  public var body: some View {
    let text = Binding(keyPath: \.text, settings: controller)

    VStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .center) {
          Text("❯").font(.custom("FiraMono-Regular", size: 22)).opacity(0.6)
          SpotlightTextField(placeholder, text: text, controller: controller)
        }.frame(height: 30).padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
        if !controller.sections.isEmpty {
          Divider()
          ScrollView {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(controller.sections, id: \.id) {
                section in
                SpotlightItemSectionView(section: section)
              }
              Spacer()
            }.padding(10)
          }
          .frame(height: 378)
          Spacer()
        }
      }
      .frame(maxWidth: 680)
      .overlay(
        RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.3), lineWidth: 1)
      )
      .background(
        VisualEffectView(
          material: NSVisualEffectView.Material.popover,
          blendingMode: NSVisualEffectView.BlendingMode.behindWindow,
          cornerRadius: 10
        )
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 25)
      )
    }
    .padding(100)
  }
}
