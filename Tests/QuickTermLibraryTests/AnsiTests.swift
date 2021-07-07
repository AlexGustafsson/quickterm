import SwiftUI
import XCTest

@testable import QuickTermLibrary

final class AnsiTests: XCTestCase {
  func testParseAnsiCodes() {
    let raw = "Hello \u{001B}[31mred\u{001B}[0mnothing\u{001B}[badcode"
    let stateChanges = Ansi.parse(raw)
    XCTAssertEqual(stateChanges.count, 2)

    var offset = String.Index(utf16Offset: 6, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 5)
      XCTAssertEqual(setState.state.color, SwiftUI.Color.red)
    }

    offset = String.Index(utf16Offset: 14, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 4)
      XCTAssertTrue(setState.state.isReset)
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
      XCTAssertEqual(setState.state.color, SwiftUI.Color.red)
    }

    offset = String.Index(utf16Offset: 5, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 4)
      XCTAssertTrue(setState.state.bold ?? false)
    }

    offset = String.Index(utf16Offset: 17, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 4)
      XCTAssertTrue(setState.state.isReset)
    }

    offset = String.Index(utf16Offset: 21, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 4)
      XCTAssertTrue(setState.state.isReset)
    }
  }

  func testDualAnsiCodes() {
    let raw = "\u{001B}[01;31mbold red"
    let stateChanges = Ansi.parse(raw)
    XCTAssertEqual(stateChanges.count, 1)

    var offset = String.Index(utf16Offset: 0, in: raw)
    XCTAssertNotNil(stateChanges[offset])
    if let setState = stateChanges[offset] {
      XCTAssertEqual(setState.count, 7)
      XCTAssertEqual(setState.state.color, SwiftUI.Color.red)
      XCTAssertTrue(setState.state.bold ?? false)
    }
  }

  func testFormatAnsiCodes() {
    let raw = "Hello \u{001B}[31mred\u{001B}[0mnothing\u{001B}[badcode"
    let formatted = Ansi.format(raw)
    XCTAssertEqual(formatted, Text("Hello ") + Text("red").foregroundColor(SwiftUI.Color.red) + Text("adcode"))
  }
}
