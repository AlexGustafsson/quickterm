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
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 5)
      XCTAssertEqual(setState.state, .color)
      XCTAssertEqual(setState.color, SwiftUI.Color.red)
    }

    offset = String.Index(utf16Offset: 14, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 4)
      XCTAssertEqual(setState.state, .reset)
    }

    offset = String.Index(utf16Offset: 25, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 3)
      XCTAssertEqual(setState.state, .unknown)
    }
  }

  func testSequentialAnsiCodes() {
    let raw = "\u{001B}[31m\u{001B}[1mbold red\u{001B}[0m\u{001B}[0m"
    let stateChanges = Ansi.parse(raw)
    XCTAssertEqual(stateChanges.count, 4)

    var offset = String.Index(utf16Offset: 0, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 5)
      XCTAssertEqual(setState.state, .color)
      XCTAssertEqual(setState.color, SwiftUI.Color.red)
    }

    offset = String.Index(utf16Offset: 5, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 4)
      XCTAssertEqual(setState.state, .bold)
    }

    offset = String.Index(utf16Offset: 17, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 4)
      XCTAssertEqual(setState.state, .reset)
    }

    offset = String.Index(utf16Offset: 21, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 4)
      XCTAssertEqual(setState.state, .reset)
    }
  }

  func testFormatAnsiCodes() {
    let raw = "Hello \u{001B}[31mred\u{001B}[0mnothing\u{001B}[badcode"
    let formatted = Ansi.format(raw)
    XCTAssertEqual(formatted, Text("Hello ") + Text("red").foregroundColor(SwiftUI.Color.red) + Text("adcode"))
  }
}
