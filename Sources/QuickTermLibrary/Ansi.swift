import SwiftUI
import os

let logger = Logger(subsystem: "se.axgn.QuickTermLibrary", category: "library")

public enum AnsiParseTreeNode {
  case string(String)
  case code(AnsiCode)
}

public class AnsiCode: CustomStringConvertible {
  let count: Int

  init(_ count: Int) {
    self.count = count
  }

  static func parse(
    firstParameter: String?,
    firstCharacter: Character?,
    secondParameter: String?,
    secondCharacter: Character?
  ) -> AnsiCode? {
    return AnsiCode(2 + (firstParameter?.count ?? 0) + 1)
  }

  public var description: String {
    return "\u{001B}[x;x"
  }
}

public enum AnsiState {
  case start, escape, bracket, firstParameter, firstCharacter, semicolon, secondParameter, secondCharacter, end
}

public class Ansi {
  static let escape = Character("\u{001B}")
  static let bracket = Character("[")
  static let semicolon = Character(";")
  static let tilde = Character("~")

  public static func format(_ text: String) -> Text {
    var color = Color.white
    var nodes = Ansi.parse(text)
    var result: Text = Text("")
    for node in nodes {
      switch node {
      case .code(let code):
        color = Color.white
      case .string(let string):
        result = result + Text(string)
      }
    }
    return result
  }

  public static func parse(_ text: String) -> [AnsiParseTreeNode] {
    var nodes: [AnsiParseTreeNode] = []
    var potentialCode = Substring(text)
    var previousNodeIndex = text.startIndex
    logger.info("Got text: \(text)")
    while let index = potentialCode.firstIndex(of: Ansi.escape) {
      logger.info("Found index of escape character")
      // Skip the escape code
      potentialCode = potentialCode[potentialCode.index(index, offsetBy: 1)..<potentialCode.endIndex]
      var state: AnsiState = .escape
      var firstParameter: String = ""
      var firstCharacter: Character? = nil
      var secondParameter: String = ""
      var secondCharacter: Character? = nil
      for character in potentialCode {
        // <char>                                -> char
        // <esc> <nochar>                        -> esc
        // <esc> <esc>                           -> esc
        // <esc> <char>                          -> Alt-keypress or keycode sequence
        // <esc> '[' <nochar>                    -> Alt-[
        // <esc> '[' (<num>) (';'<num>) '~'      -> keycode sequence, <num> defaults to 1
        if state == .escape && character == Ansi.escape {
          state = .escape
          logger.info("Escape")
        } else if state == .escape && character == Ansi.bracket {
          state = .bracket
          logger.info("Bracket")
        } else if (state == .bracket || state == .firstParameter) && character.isNumber {
          firstParameter.append(character)
          state = .firstParameter
          logger.info("First parameter")
        } else if state == .firstParameter && character != Ansi.semicolon {
          firstCharacter = character
          state = .firstCharacter
          logger.info("First character")
        } else if (state == .firstCharacter || state == .firstParameter) && character == Ansi.semicolon {
          state = .semicolon
          logger.info("Semi")
        } else if (state == .semicolon || state == .secondParameter) && character.isNumber {
          secondParameter.append(character)
          state = .secondParameter
          logger.info("Second parameter")
        } else if state == .secondParameter {
          secondCharacter = character
          state = .end
          logger.info("Second character")
        } else {
          // Unable to parse this sequence, or it has ended - go to the next
          logger.info("Unable to parse")
          break
        }
      }

      if let code = AnsiCode.parse(
        firstParameter: firstParameter,
        firstCharacter: firstCharacter,
        secondParameter: secondParameter,
        secondCharacter: secondCharacter
      ) {
        nodes.append(.string(String(text[previousNodeIndex..<index])))
        nodes.append(.code(code))
        potentialCode =
          potentialCode[potentialCode.index(potentialCode.startIndex, offsetBy: code.count)..<potentialCode.endIndex]
        previousNodeIndex = text.index(previousNodeIndex, offsetBy: code.count)
      }
    }
    nodes.append(.string(String(potentialCode)))

    return nodes
  }
}
