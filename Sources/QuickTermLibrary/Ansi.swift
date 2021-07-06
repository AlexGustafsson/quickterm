import os
import SwiftUI

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Library/ANSI")

public enum AnsiStateChange {
  case color, unknown
}

public class AnsiCode: CustomStringConvertible {
  let count: Int
  let state: AnsiStateChange
  let parameter1: Int?
  let parameter2: Int?

  init(_ state: AnsiStateChange, _ parameter1: Int?, _ parameter2: Int?, _ count: Int) {
    self.state = state
    self.parameter1 = parameter1
    self.parameter2 = parameter2
    self.count = count
  }

  static func parse(
    firstParameter: String?,
    firstCharacter: Character?,
    secondParameter: String?,
    secondCharacter _: Character?
  ) -> AnsiCode? {
    let count = 2 + (firstParameter?.count ?? 0) + 1
    let parameter1 = firstParameter == nil ? nil : Int(firstParameter!)
    let parameter2 = secondParameter == nil ? nil : Int(secondParameter!)
    switch firstCharacter {
    case Ansi.colorOperator:
      return AnsiCode(.color, parameter1, parameter2, count)
    default:
      return AnsiCode(.unknown, parameter1, parameter2, count)
    }
  }

  public var color: SwiftUI.Color {
    switch self.parameter1 {
    case 0:
      return SwiftUI.Color.black
    case 31:
      return SwiftUI.Color.red
    case 32:
      return SwiftUI.Color.green
    case 33:
      return SwiftUI.Color.blue
    default:
      return SwiftUI.Color.black
    }
  }

  public var description: String {
    "\u{001B}[x;x"
  }
}

public enum AnsiState {
  case start, escape, bracket, firstParameter, firstCharacter, semicolon, secondParameter, secondCharacter, end
}

public enum Ansi {
  static let escape = Character("\u{001B}")
  static let bracket = Character("[")
  static let semicolon = Character(";")
  static let tilde = Character("~")
  static let colorOperator = Character("m")

  public static func format(_ text: String) -> Text {
    var color = Color.white
    var nodes = Ansi.parse(text)
    var result = Text("")
    return result
  }

  public static func parse(_ text: String) -> [String.Index: AnsiCode] {
    var stateChanges: [String.Index: AnsiCode] = [:]
    var potentialCode = Substring(text)
    logger.info("Got text: \(text)")
    while let index = potentialCode.firstIndex(of: Ansi.escape) {
      logger.info("Found index of escape character")
      // Skip the escape code
      potentialCode = potentialCode[potentialCode.index(index, offsetBy: 1) ..< potentialCode.endIndex]
      var state: AnsiState = .escape
      var firstParameter: String = ""
      var firstCharacter: Character?
      var secondParameter: String = ""
      var secondCharacter: Character?
      for character in potentialCode {
        // <char>                                -> char
        // <esc> <nochar>                        -> esc
        // <esc> <esc>                           -> esc
        // <esc> <char>                          -> Alt-keypress or keycode sequence
        // <esc> '[' <nochar>                    -> Alt-[
        // <esc> '[' (<num>) (';'<num>) '~'      -> keycode sequence, <num> defaults to 1
        if state == .escape, character == Ansi.escape {
          state = .escape
          logger.info("Escape")
        } else if state == .escape, character == Ansi.bracket {
          state = .bracket
          logger.info("Bracket")
        } else if state == .bracket || state == .firstParameter, character.isNumber {
          firstParameter.append(character)
          state = .firstParameter
          logger.info("First parameter")
        } else if state == .firstParameter, character != Ansi.semicolon {
          firstCharacter = character
          state = .firstCharacter
          logger.info("First character")
        } else if state == .firstCharacter || state == .firstParameter, character == Ansi.semicolon {
          state = .semicolon
          logger.info("Semi")
        } else if state == .semicolon || state == .secondParameter, character.isNumber {
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
        stateChanges[index] = code
        potentialCode =
          potentialCode[potentialCode.index(potentialCode.startIndex, offsetBy: code.count) ..< potentialCode.endIndex]
      }
    }

    return stateChanges
  }
}
