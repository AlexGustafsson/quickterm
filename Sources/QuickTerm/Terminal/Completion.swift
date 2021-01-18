import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/Terminal/Completion")

class CompletionManager: ObservableObject {
  @Published var completions: [String] = []

  func complete(_ command: String) {
    logger.debug("Handling input view tab")
    do {
      try Completion.completeCommandOrFile(hint: command) {
        completions in
        self.objectWillChange.send()
        self.completions = completions
      }
    } catch {
      logger.error("Failed to fetch tab completions: \(error.localizedDescription)")
    }
  }

  func clear() {
    self.objectWillChange.send()
    self.completions = []
  }
}

class Completion {
  typealias CompletionCallback = ([String]) -> Void
  var onGotCompletion: CompletionCallback = { _ in }

  public static func completeCommandOrFile(
    hint: String,
    max: Int = 10,
    onGotCompletion: @escaping CompletionCallback
  ) throws {
    let command = "compgen -abcdefv '\(hint)' | sort | uniq | head -n \(max)"
    try SimpleProcess(command: command).run {
      output in
      let completions = output.split(separator: "\n").map(String.init)
      DispatchQueue.main.async {
        onGotCompletion(completions)
      }
    }
  }
}
