import AppKit

extension NSMenuItem {
  convenience init(
    title: String,
    action: Selector?,
    keyEquivalent: String,
    keyEquivalentModifierMask: NSEvent.ModifierFlags
  ) {
    self.init(title: title, action: action, keyEquivalent: keyEquivalent)
    self.keyEquivalentModifierMask = keyEquivalentModifierMask
  }
}
