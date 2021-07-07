import os
import SwiftUI

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Library/ANSI")

public enum AnsiStateChange {
  case color, unknown, bold, italic, underline, reset
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
    case Ansi.styleOperator:
      switch parameter1 {
      case 0:
        return AnsiCode(.reset, parameter1, parameter2, count)
      case 1:
        return AnsiCode(.bold, parameter1, parameter2, count)
      case 3:
        return AnsiCode(.italic, parameter1, parameter2, count)
      case 4:
        return AnsiCode(.underline, parameter1, parameter2, count)
      default:
        return AnsiCode(.color, parameter1, parameter2, count)
      }
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
  static let styleOperator = Character("m")

  public static func format(
    _ text: String,
    _ color: SwiftUI.Color,
    _ bold: Bool,
    _ italic: Bool,
    _ underline: Bool
  ) -> SwiftUI.Text {
    var part = Text(verbatim: text).foregroundColor(color)
    if bold {
      part = part.bold()
    }
    if italic {
      part = part.italic()
    }
    if underline {
      part = part.underline()
    }
    return part
  }

  public static func format(_ text: String) -> Text {
    // Current state
    var color = Color.black
    var bold = false
    var italic = false
    var underline = false

    let stateChanges = Ansi.parse(text)

    var result = Text(verbatim: "")
    var previousOffset = text.startIndex

    // Mutate the state left to right using the state changes, rendering the
    // final text using the Text's + operand with the state as the styling
    let offsets = stateChanges.keys.sorted()
    for offset in offsets {
      let state = stateChanges[offset]!
      // Render the text up until this state change
      result = result + Ansi.format(String(text[previousOffset ..< offset]), color, bold, italic, underline)

      // Modify the state
      switch state.state {
      case .color:
        color = state.color
      case .bold:
        bold = true
      case .italic:
        italic = true
      case .underline:
        underline = true
      case .reset:
        color = SwiftUI.Color.black
        bold = false
        italic = false
        underline = false
      default:
        break
      }
      // Move past the current ANSI code
      previousOffset = text.index(offset, offsetBy: state.count)
    }
    result = result + Ansi.format(String(text.suffix(from: previousOffset)), color, bold, italic, underline)
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
