import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
  private var window: NSWindow!
  private var statusItem : NSStatusItem!
  private lazy var applicationName = ProcessInfo.processInfo.processName
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let sessionManager = TerminalSessionManager()
    let contentView = ContentView(sessionManager: sessionManager)

    guard let mainScreen = NSScreen.main else {
      assertionFailure()
      return
    }

    window = NSWindow(
      contentRect: NSRect(x: mainScreen.visibleFrame.width - 345, y: -100, width: 345, height: mainScreen.visibleFrame.height),
      styleMask: .borderless,
      // styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false
    )
    window.level = .floating
    window.tabbingMode = .disallowed
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(nil)
    window.backgroundColor = .clear

    let statusBar = NSStatusBar.system
    statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.title = "⌘"
    // item?.button?.image = NSImage(named: "MenuBarIcon-Normal")!
    // item?.button?.alternateImage = NSImage(named: "MenuBarIcon-Selected")!

    let menu = NSMenu()

    menu.addItem(NSMenuItem(title: "About \(applicationName)", action: #selector(self.handleAbout), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))

    statusItem.menu = menu
  }

  // TODO: When closing the window and
  // isReleasedWhenClosed is true, the app crashes due to a segmentation fault
  @objc func handleAbout() {
    let contentView = AboutView()
    let aboutWindow = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 345, height: 245),
      styleMask: [.titled, .closable],
      backing: .buffered, defer: false
    )
    aboutWindow.isReleasedWhenClosed = false
    aboutWindow.level = .popUpMenu
    aboutWindow.contentView = NSHostingView(rootView: contentView)
    aboutWindow.title = "About \(applicationName)"
    aboutWindow.center()
    aboutWindow.makeKeyAndOrderFront(nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // TODO: stop all processes?
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }
}
