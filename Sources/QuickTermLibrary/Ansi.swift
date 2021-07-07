import SwiftUI

public struct DecoratedString {
  private let parsed: ANSIParseTree
  public let value: String

  init(fromString text: String) {
    self.parsed = ANSIParser.parse(text)
    self.value = text
  }
}

public enum ASCIIControlCharacter: Character {
  case bell = "\u{0007}"
  case backspace = "\u{0008}"
  case horizontalTab = "\u{0009}"
  case linefeed = "\u{000A}"
  case verticalTab = "\u{000B}"
  case formfeed = "\u{000C}"
  case carriageReturn = "\u{000D}"
  case escapeCharacter = "\u{001B}"
  case deleteCharacter = "\u{007F}"
}

public enum ANSIGraphicsMode: Equatable {
  case reset, bold, dim, italic, underline, blinking, inverse, invisible, strikethrough, foreground(Color),
       background(Color)
  public static func == (lhs: ANSIGraphicsMode, rhs: ANSIGraphicsMode) -> Bool {
    switch (lhs, rhs) {
    case let (.foreground(a), .foreground(b)), let (.background(a), .background(b)):
      return a == b
    case (.reset, .reset), (.bold, .bold), (.dim, .dim), (.italic, .italic), (.underline, .underline),
         (.blinking, .blinking), (.inverse, .inverse), (.invisible, .invisible), (.strikethrough, .strikethrough):
      return true
    default:
      return false
    }
  }
}

public enum ANSIEscapeSequence: Equatable {
  case cursorControl, eraseFunction, graphicsMode(ANSIGraphicsMode), screenMode

  public static func == (lhs: ANSIEscapeSequence, rhs: ANSIEscapeSequence) -> Bool {
    switch (lhs, rhs) {
    case let (.graphicsMode(a), .graphicsMode(b)):
      return a == b
    case (.cursorControl, .cursorControl), (.eraseFunction, .eraseFunction), (.screenMode, .screenMode):
      return true
    default:
      return false
    }
  }
}

public typealias BoundedEscapeSequence = (count: Int, sequence: ANSIEscapeSequence)

public typealias ANSIParseTree = (
  controlCharacters: [String.Index: ASCIIControlCharacter],
  escapeSequences: [String.Index: BoundedEscapeSequence]
)

public enum ANSIParser {
  private static let cursorControlPattern = #"^\[(([Hsu])|(\d+;\d+[Hf])|(\d+[ABCDEFG])|(6n))"#
  private static let eraseFunctionsPattern = #"^\[(([012]?)([JK]))"#
  private static let graphicsModePattern = #"^\[(\d+)((;\d+)*)m"#
  private static let screenModePattern = #"^\[=(\d+)([hl])"#

  public static func parse(_ text: String) -> ANSIParseTree {
    var controlCharacters: [String.Index: ASCIIControlCharacter] = [:]
    var escapeSequences: [String.Index: BoundedEscapeSequence] = [:]

    for var i in 0 ..< text.count {
      let index = text.index(text.startIndex, offsetBy: i)
      if let controlCharacter = ASCIIControlCharacter(rawValue: text[index]) {
        controlCharacters[index] = controlCharacter

        if controlCharacter == ASCIIControlCharacter.escapeCharacter {
          let sequenceIndex = text.index(text.startIndex, offsetBy: i + 1)
          if let escapeSequence = parseEscapeSequence(text[sequenceIndex ..< text.endIndex], &i) {
            escapeSequences[index] = escapeSequence
          }
        }
      }
    }

    return (controlCharacters, escapeSequences)
  }

  private static func parseEscapeSequence(
    _ text: Substring,
    _ i: inout Int
  ) -> (count: Int, sequence: ANSIEscapeSequence)? {
    do {
      let regex = try NSRegularExpression(pattern: graphicsModePattern)
      if let match = regex.firstMatch(in: String(text), range: NSRange(text.startIndex..., in: text)) {
        let part0 = text[Range(match.range(at: 0), in: text)!]
        let part1 = text[Range(match.range(at: 1), in: text)!]
        let part2 = text[Range(match.range(at: 2), in: text)!]
        let length = 1 + part0.count
        i += length
        let escapeSequence = ANSIEscapeSequence.graphicsMode(ANSIGraphicsMode.foreground(Color.red))
        return (length, escapeSequence)
      }
    } catch {
      print("\(error)")
      return nil
    }

    return nil
  }
}
