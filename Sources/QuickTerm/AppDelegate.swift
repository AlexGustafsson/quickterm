import AppKit
import SwiftUI

import QuickTermShared

class AppDelegate: NSObject, NSApplicationDelegate {
  private var window: NSWindow!
  private var statusItem: NSStatusItem!
  private let applicationName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""

  private let sessionManager: TerminalSessionManager!

  private let delegate: CommandExecutorDelegate!
  private let executor: CommandExecutor!
  private let connection: NSXPCConnection!
  private let listener: NSXPCListener!

  override init() {
    self.sessionManager = TerminalSessionManager()

    self.connection = NSXPCConnection(serviceName: "se.axgn.QuickTerm.Broker")
    self.connection.remoteObjectInterface = NSXPCInterface(with: BrokerProtocol.self)

    self.listener = NSXPCListener.anonymous()

    self.executor = CommandExecutor()

    self.delegate = CommandExecutorDelegate(executor: executor)
    self.listener.delegate = self.delegate;
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let contentView = ContentView(sessionManager: sessionManager)

    guard let mainScreen = NSScreen.main else {
      logger.error("Unable to find main screen")
      return
    }

    window = NSWindow(
      contentRect: NSRect(
        x: mainScreen.visibleFrame.maxX - 345 - 15,
        y: mainScreen.visibleFrame.minY,
        width: 345,
        height: mainScreen.visibleFrame.height
      ),
      // Toggling between these two lines are useful for debugging the UI
      styleMask: .borderless,
      // styleMask: .titled,
      backing: .buffered,
      defer: false
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
    menu.addItem(
      NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
    )

    statusItem.menu = menu

    executor.onExecuteCommand = {
      configuration in
      logger.info("Received command to execute in \(configuration.workingDirectory, privacy: .public): \(configuration.command)")
      let session = TerminalSession(configuration)

      // TODO: handle delayed start etc.

      // Add the session when started
      session.onStarted = {
        _ in
        DispatchQueue.main.async {
          self.sessionManager.append(session)
        }
      }

      // Remove the session when terminated
      session.onTerminated = {
        _ in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.sessionManager.remove(session)
        }
      }

      do {
        logger.info("Starting session")
        try session.start()
      } catch {
        logger.error("Unable to start session: \(error.localizedDescription)")
      }
    }

    self.connection.interruptionHandler = {
      logger.info("Disconnected from broker (interrupted)")
      // TODO: crash the app?
    };

    self.connection.invalidationHandler = {
      logger.info("Disconnected from broker (invalidated)")
      // TODO: crash the app?
    };

    logger.info("Connecting to broker")
    self.listener.resume()
    self.connection.resume()

    let service = self.connection.synchronousRemoteObjectProxyWithErrorHandler {
      error in
      logger.error("Unable to get remote service: \(error.localizedDescription, privacy: .public)")
    } as? BrokerProtocol

    logger.info("Registering self as an executor")
    service!.registerCommandExecutor(client: self.listener.endpoint)
  }

  // TODO: When closing the window and
  // isReleasedWhenClosed is true, the app crashes due to a segmentation fault
  @objc func handleAbout() {
    let contentView = AboutView()
    let aboutWindow = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 345, height: 245),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
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

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return false }
}
