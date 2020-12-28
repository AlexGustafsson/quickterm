import SwiftUI

public struct SpotlightSectionHeaderView: View {
  let text: String

  public init(_ text: String) {
    self.text = text
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Divider().padding(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
      Text(text)
        .font(.system(size: 11))
        .opacity(0.4)
        .padding(.init(top: 0, leading: 2, bottom: 0, trailing: 2))
    }.padding(.init(top: 4, leading: 4, bottom: 3, trailing: 4))
  }
}
