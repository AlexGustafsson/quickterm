import AppKit
import HotKey

public extension HotKey {
  convenience init?(keys: String, keyDownHandler: Handler? = nil, keyUpHandler: Handler? = nil) {
    guard let keyCombo = KeyCombo(keys: keys) else {
      return nil
    }
    self.init(keyCombo: keyCombo, keyDownHandler: keyDownHandler, keyUpHandler: keyUpHandler)
  }
}

public extension KeyCombo {
  init?(keys: String) {
    var chosenKey: Key?
    var chosenModifiers: NSEvent.ModifierFlags = []
    for key in keys.split(separator: "+") {
      guard let parsedKey = Key(string: String(key)) else {
        // Parse failed
        return nil
      }

      switch parsedKey {
      case .command: chosenModifiers = chosenModifiers.union(.command)
      case .rightCommand: chosenModifiers = chosenModifiers.union(.command)
      case .option: chosenModifiers = chosenModifiers.union(.option)
      case .rightOption: chosenModifiers = chosenModifiers.union(.option)
      case .control: chosenModifiers = chosenModifiers.union(.control)
      case .rightControl: chosenModifiers = chosenModifiers.union(.control)
      case .shift: chosenModifiers = chosenModifiers.union(.shift)
      case .rightShift: chosenModifiers = chosenModifiers.union(.shift)
      case .function: chosenModifiers = chosenModifiers.union(.function)
      case .capsLock: chosenModifiers = chosenModifiers.union(.capsLock)
      default:
        chosenKey = parsedKey
      }
    }

    if chosenKey == nil {
      return nil
    }
    self.init(carbonKeyCode: chosenKey!.carbonKeyCode, carbonModifiers: chosenModifiers.carbonFlags)
  }
}
