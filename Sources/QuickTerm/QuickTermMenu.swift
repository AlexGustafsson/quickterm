import AppKit

class QuickTermMenu: NSObject {
  private var statusItem: NSStatusItem!
  private var menu: NSMenu!

  private let applicationName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""

  typealias MenuItemClickedCallback = () -> Void
  var onShowAbout: MenuItemClickedCallback = { }
  var onShowCommandEntry: MenuItemClickedCallback = { }
  var onOpenConfigurationFile: MenuItemClickedCallback = { }
  var onQuit: MenuItemClickedCallback = { }

  override init() {
    super.init()

    self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    self.statusItem.button?.title = "⌘"

    self.menu = NSMenu()

    // About QuickTerm
    self.menu.addItem(NSMenuItem(title: "About \(self.applicationName)", action: #selector(self.showAbout), target: self, keyEquivalent: ""))
    // --
    self.menu.addItem(NSMenuItem.separator())
    // Show Command Entry
    self.menu.addItem(
      NSMenuItem(
        title: "Show Command Entry",
        action: #selector(self.showCommandEntry),
        target: self,
        keyEquivalent: "t",
        keyEquivalentModifierMask: [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.option]
      )
    )
    // --
    self.menu.addItem(NSMenuItem.separator())
    // Open Configuration File
    self.menu.addItem(
      NSMenuItem(
        title: "Open Configuration File",
        action: #selector(self.openConfigurationFile),
        target: self,
        keyEquivalent: ""
      )
    )
    // Quit QuickTerm
    self.menu.addItem(
      NSMenuItem(title: "Quit \(applicationName)", action: #selector(self.quit), target: self, keyEquivalent: "")
    )

    self.statusItem.menu = self.menu
  }

  @objc func showAbout() {
    self.onShowAbout()
  }

  @objc func showCommandEntry() {
    self.onShowCommandEntry()
  }

  @objc func openConfigurationFile() {
    self.onOpenConfigurationFile()
  }

  @objc func quit() {
    self.onQuit()
  }
}
