import SwiftUI
import XCTest

@testable import QuickTermLibrary

final class AnsiTests: XCTestCase {
  func testParseAnsiCodes() {
    let raw = "Hello \u{001B}[31mred\u{001B}[0mnothing\u{001B}[badcode"
    let stateChanges = Ansi.parse(raw)
    XCTAssertEqual(stateChanges.count, 3)

    var offset = String.Index(utf16Offset: 6, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setColor = stateChanges[offset] {
      XCTAssertEqual(setColor.count, 5)
      XCTAssertEqual(setColor.state, .color)
      XCTAssertEqual(setColor.color, SwiftUI.Color.red)
    }

    offset = String.Index(utf16Offset: 14, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setColor = stateChanges[offset] {
      XCTAssertEqual(setColor.count, 4)
      XCTAssertEqual(setColor.state, .color)
      XCTAssertEqual(setColor.color, SwiftUI.Color.black)
    }

    offset = String.Index(utf16Offset: 25, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let bad = stateChanges[offset] {
      XCTAssertEqual(bad.count, 3)
      XCTAssertEqual(bad.state, .unknown)
    }
  }

  func testFormatAnsiCodes() {
    let raw = "Hello \u{001B}[31mred\u{001B}[0mnothing\u{001B}[badcode"
    let expected = "Hello red nothing badcode"
    let formatted = Ansi.format(raw)
    XCTAssertEqual(formatted, Text("Hello ") + Text("red").foregroundColor(SwiftUI.Color.red) + Text("adcode"))
  }
}
