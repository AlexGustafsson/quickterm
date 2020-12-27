import SwiftUI

extension Binding {
  init<A>(keyPath: ReferenceWritableKeyPath<A, Value>, settings: A) {
    self.init(
      get: { settings[keyPath: keyPath] },
      set: { settings[keyPath: keyPath] = $0 }
    )
  }
}
