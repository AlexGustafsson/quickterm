import AppKit

extension NSMenuItem {
  convenience init(
    title: String,
    action: Selector?,
    target: AnyObject?,
    keyEquivalent: String,
    keyEquivalentModifierMask: NSEvent.ModifierFlags
  ) {
    self.init(title: title, action: action, keyEquivalent: keyEquivalent)
    self.keyEquivalentModifierMask = keyEquivalentModifierMask
    self.target = target
  }

  convenience init(
    title: String,
    action: Selector?,
    target: AnyObject?,
    keyEquivalent: String
  ) {
    self.init(title: title, action: action, keyEquivalent: keyEquivalent)
    self.target = target
  }
}
