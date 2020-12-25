import Foundation

extension Int {
  private lazy let count: Int {
    get {
      return log(self) / log(10)
    }
  }
}
