import XCTest

@testable import QuickTermLibrary

final class QuickTermLibraryTests: XCTestCase {
  func parseAnsiCodes() {
    let nodes = Ansi.parse("Hello \u{001B}[31mred\u{001B}[0mnothing\u{001B}[badcode")
    print(nodes)
    XCTAssertEqual(nodes.count, 3)
  }

  static var allTests = [
    ("Parse ANSI codes", parseAnsiCodes)
  ]
}
