import Foundation

public class Ansi {
  public static let EscapeCharacter = Character("\u{001B}")
  public static let BracketCharacter = Character("[")
  public static let SemicolonCharacter = Character(";")
  public static let TildeCharacter = Character("~")
  public static let AllowedCharacters = "ABCDEFGHJKSTfmin"

  public class Code {
    public let escape: String
    public let argument1: Int
    public let argument2: Int?
    public let character: Character
    public lazy let count: Int {
      get {
        var length = escape.count
        length += self.argument1.count
        if self.argument2 != nil {
          // 1 for ';'
          length += 1
          length += self.argument2.count
        }
        // 1 for the character
        length += 1
      }
    }
  }

  public class Canvas {
    public var width: Int = 80
    public var height: Int = 40

    public func render() -> String {

    }

    public func feed(text: String) {

    }
  }

  public static func render(text: String) {

  }

  public static func parse(text: String) {
    var slice = Substring(text)
    var previousSlice: Substring? = nil
    while let index = slice.firstIndex(of: Ansi.escape) {
      logger.info("Found index of escape character")
      // Create a slice of the potential ANSI code
      let potentialCode = slice[slice.index(slice.startIndex, offsetBy: index)..<slice.endIndex]
      if let code = parseCode(potentialCode) {
        // Consume the escape code
        slice = slice.offset(by: code.count)
        // TODO: push the code to some AnsiString / state - including its offset in the global string
        // the state can be used to render the text. Using the codes' offsets
        // Create some "canvas" with configurable sizes which could be used to communicate cursor positions
      } else {
        // Consume the escape character to avoid infinite loops
        slice = slice.offset(by: 1)
      }
    }
  }

  class func parseCode(potentialCode: Substring) -> Code? {
    // Require at least one escape character
    if offset == 0 {
      return nil
    }

    // Parse all escape charactes
    guard let escape = consumeAll(text, of: {
      character in
      return character == EscapeCharacter
    }) else {
      return nil
    }

    // Parse the opening bracket
    guard let bracket = consumeAll(text, of: {
      character in
      return character == BracketCharacter
    }) else {
      return nil
    }

    // Parse the first argument (any number)
    guard let argument1 = consumeAll(text, of: {
      character in
      return character.isNumber
    }) else {
      return nil
    }

    // If there's a ';', parse it and the second argument (any number)
    var argument2: Substring? = nil
    if consumeAll(text, of: {
      character in
      return character == SemicolonCharacter
    }) != nil {
      argument2 = consumeAll(text, of: {
        character in
        return character.isNumber
      })
      if argument2 == nil {
        return nil
      }
    }

    // Parse the trailing character
    guard let character = consumeAll(text, of: {
      character in
      return AllowedCharacters.contains(character)
    }) else {
      return nil
    }

    // Parse the code
    guard let code = Code(
      escape: escape,
      argument1: argument1,
      argument2: argument2,
      character: character
    ) else {
      return nil
    }
  }
}
