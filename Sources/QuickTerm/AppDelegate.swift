import AppKit
import SwiftUI

import QuickTermShared

class AppDelegate: NSObject, NSApplicationDelegate {
  private let notificationViewController: NotificationViewController!

  private var statusItem: NSStatusItem!
  private let applicationName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""

  private let sessionManager: TerminalSessionManager!

  private let delegate: CommandExecutorDelegate!
  private let executor: CommandExecutor!
  private let connection: NSXPCConnection!
  private let listener: NSXPCListener!

  override init() {
    self.sessionManager = TerminalSessionManager()
    self.notificationViewController = NotificationViewController(sessionManager: self.sessionManager)

    self.connection = NSXPCConnection(serviceName: "se.axgn.QuickTerm.Broker")
    self.connection.remoteObjectInterface = NSXPCInterface(with: BrokerProtocol.self)

    self.listener = NSXPCListener.anonymous()

    self.executor = CommandExecutor()

    self.delegate = CommandExecutorDelegate(executor: executor)
    self.listener.delegate = self.delegate;
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let statusBar = NSStatusBar.system
    statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.title = "⌘"
    // item?.button?.image = NSImage(named: "MenuBarIcon-Normal")!
    // item?.button?.alternateImage = NSImage(named: "MenuBarIcon-Selected")!

    self.notificationViewController.show()

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
    let viewController = AboutViewController()
    viewController.show()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // TODO: stop all processes?
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return false }
}
