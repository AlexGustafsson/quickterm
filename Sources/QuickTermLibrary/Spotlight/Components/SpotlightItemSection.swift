import Foundation
import SwiftUI

public class SpotlightItemSection: Identifiable, ObservableObject {
  @Published var title: String? = nil
  @Published var items: [SpotlightItem] = []

  public init(title: String?, items: [SpotlightItem]) {
    self.title = title
    self.items = items
  }

  public let id = UUID()

  static func == (lhs: SpotlightItemSection, rhs: SpotlightItemSection) -> Bool {
    lhs.id == rhs.id
  }
}

public struct SpotlightItemSectionView: View {
  @ObservedObject var section: SpotlightItemSection

  public var body: some View {
    Group {
      if section.title != nil {
        SpotlightSectionHeaderView(section.title ?? "")
      }
      ForEach(section.items, id: \.id) {
        item in
        SpotlightItemView(item: item)
      }
    }
  }
}
