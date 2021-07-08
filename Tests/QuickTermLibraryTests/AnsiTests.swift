import SwiftUI
import XCTest

@testable import QuickTermLibrary

func assertEscapeSequence(_ text: String, _ tree: ANSIParseTree, _ index: Int) -> BoundedEscapeSequence? {
  let offset = text.index(text.startIndex, offsetBy: index)
  XCTAssertNotNil(tree.controlCharacters[offset])
  XCTAssertNotNil(tree.escapeSequences[offset])
  return tree.escapeSequences[offset]
}

final class ANSIParserTests: XCTestCase {
  func testParseColorCodes() {
    let simple = "Hello \u{001B}[31mred"
    let tree = ANSIParser.parse(simple)

    XCTAssertEqual(tree.controlCharacters.count, 1)
    XCTAssertEqual(tree.escapeSequences.count, 1)

    if let setColor = assertEscapeSequence(simple, tree, 6) {
      XCTAssertEqual(setColor.count, 5)
      if case let .graphicsModes(modes) = setColor.sequence {
        XCTAssertEqual(modes, [ANSIGraphicsMode.foreground(Color.red)])
      } else {
        XCTFail("Expected grapics modes")
      }
    }
  }

  func testParseVariousCodes() {
    let simple = "\u{001B}[10;10Hmovecursor\u{001B}[1;3;31msetgraphics"
    let tree = ANSIParser.parse(simple)

    XCTAssertEqual(tree.controlCharacters.count, 2)
    XCTAssertEqual(tree.escapeSequences.count, 2)

    if let moveCursor = assertEscapeSequence(simple, tree, 0) {
      XCTAssertEqual(moveCursor.count, 8)
      XCTAssertEqual(moveCursor.sequence, ANSIEscapeSequence.cursorControl)
    }

    if let setColor = assertEscapeSequence(simple, tree, 18) {
      XCTAssertEqual(setColor.count, 9)
      XCTAssertEqual(setColor.sequence, ANSIEscapeSequence.graphicsModes([.bold, .italic, .foreground(Color.red)]))
    }
  }
}
