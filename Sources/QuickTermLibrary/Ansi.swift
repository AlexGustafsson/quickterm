import os
import SwiftUI

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Library/ANSI")

private enum AnsiValue {
  case reset
  case bold
  case italic
  case underline
  case color(SwiftUI.Color)
}

private let mapping: [Int: AnsiValue] = [
  0: .reset,
  1: .bold,
  4: .italic,
  5: .underline,
  30: .color(Color.black),
  31: .color(Color.red),
  32: .color(Color.green),
  33: .color(Color.yellow),
  34: .color(Color.blue),
  35: .color(Color(red: 0.79, green: 0.26, blue: 0.76)),
  36: .color(Color(red: 0.30, green: 0.78, blue: 0.73)),
  37: .color(Color.white),
]

public struct AnsiState {
  public var color: SwiftUI.Color?
  public var bold: Bool?
  public var italic: Bool?
  public var underline: Bool?
  public var isReset = false

  mutating func reset() {
    self.color = nil
    self.bold = nil
    self.italic = nil
    self.underline = nil
    self.isReset = true
  }

  func format(_ text: String) -> SwiftUI.Text {
    var part = Text(verbatim: text).foregroundColor(self.color)
    if self.bold ?? false {
      part = part.bold()
    }
    if self.italic ?? false {
      part = part.italic()
    }
    if self.underline ?? false {
      part = part.underline()
    }
    return part
  }

  static func + (left: AnsiState, right: AnsiState) -> AnsiState {
    if right.isReset {
      return AnsiState(color: nil, bold: nil, italic: nil, underline: nil, isReset: true)
    }

    return AnsiState(
      color: right.color ?? left.color,
      bold: right.bold ?? left.bold,
      italic: right.italic ?? left.italic,
      underline: right.underline ?? left.underline,
      isReset: false
    )
  }
}

public class AnsiCode: CustomStringConvertible {
  let count: Int
  let parameter1: Int
  let parameter2: Int?
  let operatorCharacter: Character
  var state: AnsiState!

  init(_ parameter1: Int, _ parameter2: Int?, _ operatorCharacter: Character, _ count: Int) {
    self.parameter1 = parameter1
    self.parameter2 = parameter2
    self.operatorCharacter = operatorCharacter
    self.count = count
    self.state = self.createState()
  }

  static func parse(
    firstParameter: String,
    secondParameter: String?,
    operatorCharacter: Character
  ) -> AnsiCode? {
    // \e + [ + x + (; + y)? + z
    let count = 2 + firstParameter.count + (secondParameter == nil ? 0 : 1 + secondParameter!.count) + 1
    let parameter1 = Int(firstParameter)!
    let parameter2 = secondParameter == nil ? nil : Int(secondParameter!)
    return AnsiCode(parameter1, parameter2, operatorCharacter, count)
  }

  private func populateState(_ state: inout AnsiState, _ value: AnsiValue) {
    switch value {
    case .bold:
      state.bold = true
    case .italic:
      state.italic = true
    case .reset:
      state.reset()
    case .underline:
      state.underline = true
    case let .color(color):
      state.color = color
    }
  }

  private func createState() -> AnsiState? {
    if self.operatorCharacter == Ansi.styleOperator {
      var state = AnsiState()

      if let value = mapping[self.parameter1] {
        self.populateState(&state, value)
      }

      if self.parameter2 != nil, let value = mapping[self.parameter2!] {
        self.populateState(&state, value)
      }

      return state
    }

    return nil
  }

  public var description: String {
    "\u{001B}[x;x"
  }
}

public enum AnsiParseState {
  case start, escape, bracket, firstParameter, firstCharacter, semicolon, secondParameter, secondCharacter, end
}

public enum Ansi {
  static let escape = Character("\u{001B}")
  static let bracket = Character("[")
  static let semicolon = Character(";")
  static let tilde = Character("~")
  static let styleOperator = Character("m")

  public static func format(_ text: String) -> Text {
    // Current state
    var state = AnsiState()

    let codes = Ansi.parse(text)

    var result = Text(verbatim: "")
    var previousOffset = text.startIndex

    // Mutate the state left to right using the state changes, rendering the
    // final text using the Text's + operand with the state as the styling
    let offsets = codes.keys.sorted()
    for offset in offsets {
      let code = codes[offset]!
      // Render the text up until this state change
      result = result + state.format(String(text[previousOffset ..< offset]))

      // Modify the state
      if code.state != nil {
        state = state + code.state!
      }
      // Move past the current ANSI code
      previousOffset = text.index(offset, offsetBy: code.count)
    }
    result = result + state.format(String(text.suffix(from: previousOffset)))
    return result
  }

  public static func parse(_ text: String) -> [String.Index: AnsiCode] {
    var stateChanges: [String.Index: AnsiCode] = [:]
    var potentialCode = Substring(text)
    while let index = potentialCode.firstIndex(of: Ansi.escape) {
      // Skip the escape code
      potentialCode = potentialCode[potentialCode.index(index, offsetBy: 1) ..< potentialCode.endIndex]
      var state: AnsiParseState = .escape
      var firstParameter: String = ""
      var secondParameter: String?
      var operatorCharacter: Character?
      for character in potentialCode {
        // <char>                                -> char
        // <esc> <nochar>                        -> esc
        // <esc> <esc>                           -> esc
        // <esc> <char>                          -> Alt-keypress or keycode sequence
        // <esc> '[' <nochar>                    -> Alt-[
        // <esc> '[' (<num>) (';'<num>) '~'      -> keycode sequence, <num> defaults to 1
        if state == .escape, character == Ansi.escape {
          state = .escape
        } else if state == .escape, character == Ansi.bracket {
          state = .bracket
        } else if state == .bracket || state == .firstParameter, character.isNumber {
          firstParameter.append(character)
          state = .firstParameter
        } else if state == .firstParameter, character != Ansi.semicolon {
          operatorCharacter = character
          state = .firstCharacter
        } else if state == .firstCharacter || state == .firstParameter, character == Ansi.semicolon {
          state = .semicolon
        } else if state == .semicolon || state == .secondParameter, character.isNumber {
          if secondParameter == nil {
            secondParameter = ""
          }

          secondParameter?.append(character)
          state = .secondParameter
        } else if state == .secondParameter {
          operatorCharacter = character
          state = .end
        } else {
          // Unable to parse this sequence, or it has ended - go to the next
          break
        }
      }

      if operatorCharacter == nil {
        continue
      }

      if let code = AnsiCode.parse(
        firstParameter: firstParameter,
        secondParameter: secondParameter,
        operatorCharacter: operatorCharacter!
      ) {
        stateChanges[index] = code
        potentialCode =
          potentialCode[
            potentialCode.index(potentialCode.startIndex, offsetBy: code.count - 1) ..< potentialCode
              .endIndex
          ]
      }
    }
    return stateChanges
  }
}
