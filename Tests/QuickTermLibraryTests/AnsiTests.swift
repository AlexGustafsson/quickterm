import SwiftUI
import XCTest

@testable import QuickTermLibrary

final class ANSIParserTests: XCTestCase {
  func testParseColorCodes() {
    let simple = "Hell \u{001B}[31mred"
    let tree = ANSIParser.parse(simple)

    XCTAssertEqual(tree.controlCharacters.count, 1)
    XCTAssertEqual(tree.escapeSequences.count, 1)
    let offset = simple.index(simple.startIndex, offsetBy: 5)
    XCTAssertNotNil(tree.controlCharacters[offset])
    XCTAssertNotNil(tree.escapeSequences[offset])
    if let setColor = tree.escapeSequences[offset] {
      XCTAssertEqual(setColor.count, 5)
      XCTAssertEqual(setColor.sequence, ANSIEscapeSequence.graphicsMode(ANSIGraphicsMode.foreground(Color.red)))
    }
  }
}
