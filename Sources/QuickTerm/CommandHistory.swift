import Foundation
import os

class CommandHistoryManager: ObservableObject {
  @Published var items: [CommandHistoryItem] = []

  func append(_ command: CommandHistoryItem) {
    objectWillChange.send()
    self.items.append(command)
  }

  func remove(_ command: CommandHistoryItem) {
    objectWillChange.send()
    if let index = self.items.firstIndex(of: command) {
      self.items.remove(at: index)
    }
  }
}

class CommandHistoryItem: Identifiable, ObservableObject, Equatable {
  public let id = UUID()

  public let command: String
  public let executionDate: Date

  init(_ command: String) {
    self.command = command
    self.executionDate = Date()
  }

  static func ==(lhs: CommandHistoryItem, rhs: CommandHistoryItem) -> Bool {
    lhs.id == rhs.id
  }
}
