import SwiftUI

public enum AnsiParseTreeNode {
case string(String)
case code(AnsiCode)
}

public class AnsiCode: CustomStringConvertible {
  let count: Int

  init() {
    self.count = 0
  }

  static func parse(firstParameter: String?, firstCharacter: Character?, secondParameter: String?, secondCharacter: Character?) -> AnsiCode? {
    return AnsiCode()
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

  static func format(_ text: String) -> Text {
    return Text("Hello, ") + Text("world").foregroundColor(Color.red) + Text("!")
  }

  static func parse(_ text: String) -> [AnsiParseTreeNode] {
    var nodes: [AnsiParseTreeNode] = []
    var potentialCode = Substring(text)
    var previousNodeIndex = text.startIndex
    while let index = potentialCode.firstIndex(of: Ansi.escape) {
      potentialCode = potentialCode[index ..< potentialCode.endIndex]
      var state: AnsiState = .start
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
        if (state == .start || state == .escape) && character == Ansi.escape {
          state = .escape
        } else if state == .escape && character == Ansi.bracket {
          state = .bracket
        } else if (state == .bracket || state == .firstParameter) && character.isNumber {
          firstParameter.append(character)
        } else if state == .firstParameter && character != Ansi.semicolon {
          firstCharacter = character
          state = .firstCharacter
        } else if (state == .firstCharacter || state == .firstParameter) && character == Ansi.semicolon {
          state = .semicolon
        } else if (state == .semicolon || state == .secondParameter) && character.isNumber {
          secondParameter.append(character)
          state = .secondParameter
        } else if state == .secondParameter {
          secondCharacter = character
          state = .end
        } else {
          // Unable to parse this sequence, or it has ended - go to the next
          break
        }
      }

      if let code = AnsiCode.parse(firstParameter: firstParameter, firstCharacter: firstCharacter, secondParameter: secondParameter, secondCharacter: secondCharacter) {
        nodes.append(.string(String(text[previousNodeIndex ..< index])))
        nodes.append(.code(code))
        potentialCode = potentialCode[potentialCode.index(potentialCode.startIndex, offsetBy: code.count) ..< potentialCode.endIndex]
        previousNodeIndex = text.index(previousNodeIndex, offsetBy: code.count)
      } else {
        potentialCode = potentialCode[potentialCode.index(potentialCode.startIndex, offsetBy: 1) ..< potentialCode.endIndex]
      }
    }

    return nodes
  }
}
