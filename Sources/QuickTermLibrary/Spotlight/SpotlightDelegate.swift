public protocol SpotlightDelegate {
  /// The window will show. Optional.
  func willShow()
  /// The window has been shown. Optional.
  func shown()

  /// The window will hide. Optional.
  func willHide()
  /// The window has been hidden. Optional.
  func hidden()

  /// The text changed. Optional.
  func textChanged(text: String)

  /// The tab key was clicked. Optional.
  func tabClicked()

  /// A key was pressed with the command key being down. Return whether or not the key was handled. Optional.
  func keyWithCommandPressed(character: String) -> Bool
  /// A key was pressed with the control key being down. Return whether or not the key was handled. Optional.
  func keyWithControlPressed(character: String) -> Bool
  /// A key was pressed with the command and shift key being down. Return whether or not the key was handled. Optional.
  func keyWithCommandAndShiftPressed(character: String) -> Bool

  /// The user submitted the request. Optional.
  func commit()
  /// The user canceled the request. Optional.
  func cancel()
}

extension SpotlightDelegate {
  func willShow() {}
  func shown() {}

  func willHide() {}
  func hidden() {}

  func textChanged(text _: String) {}

  func tabClicked() {}

  func keyWithCommandPressed(character _: String) -> Bool { false }
  func keyWithControlPressed(character _: String) -> Bool { false }
  func keyWithCommandAndShiftPressed(character _: String) -> Bool { false }

  func commit() {}
  func cancel() {}
}
