import SwiftUI

// Remove the focus highlight of all text fields
extension NSTextField {
  open override var focusRingType: NSFocusRingType {
    get { .none }
    set { }
  }
}
