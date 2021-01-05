import Foundation
import SwiftUI

public class SpotlightItem: Identifiable, ObservableObject {
  @Published var text: String
  @Published var detail: String
  @Published var selected: Bool = false
  @Published var textToComplete: String? = nil
  @Published var textToInsert: String? = nil

  public let id = UUID()

  public init(text: String, detail: String, textToComplete: String? = nil, textToInsert: String? = nil) {
    self.text = text
    self.detail = detail
    self.textToComplete = textToComplete
    self.textToInsert = textToInsert
  }

  static func == (lhs: SpotlightItem, rhs: SpotlightItem) -> Bool {
    lhs.id == rhs.id
  }
}

public struct SpotlightItemView: View {
  @ObservedObject var item: SpotlightItem

  public var body: some View {
    HStack(alignment: .center, spacing: 0) {
      RoundedRectangle(cornerRadius: 5).fill(Color.white).frame(width: 16, height: 16)
      Spacer().frame(width: 10)
      Text(item.text)
      Text(item.detail).opacity(0.6)
      Spacer()
    }
    .frame(height: 11)
    .padding(7)
    .cornerRadius(5)
    .background(item.selected ? Color.blue : Color.clear)
  }
}
