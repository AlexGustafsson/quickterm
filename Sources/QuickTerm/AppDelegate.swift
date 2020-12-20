import AppKit
import SwiftUI

import QuickTermShared
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
  private let notificationViewController: NotificationViewController!
  private let inputViewController: InputViewController!

  private var statusItem: NSStatusItem!
  private let applicationName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""

  private let sessionManager: TerminalSessionManager!

  private let delegate: CommandExecutorDelegate!
  private let executor: CommandExecutor!
  private let connection: NSXPCConnection!
  private let listener: NSXPCListener!

  private let commandEntryHotKey: HotKey!

  override init() {
    self.sessionManager = TerminalSessionManager()
    self.notificationViewController = NotificationViewController(sessionManager: self.sessionManager)
    self.inputViewController = InputViewController()

    self.connection = NSXPCConnection(serviceName: "se.axgn.QuickTerm.Broker")
    self.connection.remoteObjectInterface = NSXPCInterface(with: BrokerProtocol.self)

    self.listener = NSXPCListener.anonymous()

    self.executor = CommandExecutor()

    self.delegate = CommandExecutorDelegate(executor: executor)
    self.listener.delegate = self.delegate;

    self.commandEntryHotKey = HotKey(key: .t, modifiers: [.command, .option])
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
    menu.addItem(NSMenuItem(title: "Show command entry", action: #selector(self.handleCommandEntry), keyEquivalent: "t", keyEquivalentModifierMask: [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.option]))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(
      NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
    )

    statusItem.menu = menu

    executor.onExecuteCommand = {
      configuration in
      if let json = try? configuration.dump() {
        logger.info("Received command to execute in \(configuration.workingDirectory, privacy: .public): \(json, privacy: .public)")
      } else {
        logger.info("Received command to execute in \(configuration.workingDirectory, privacy: .public): \(configuration.command)")
      }
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

    logger.info("Registering global hotkey")

    self.commandEntryHotKey.keyDownHandler = {
      self.handleCommandEntry()
    }

    self.inputViewController.onExecuteCommand = {
      command in
      let workingDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      let configuration = CommandConfiguration(
        workingDirectory: workingDirectory,
        command: command
      )

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
  }

  // TODO: When closing the window and
  // isReleasedWhenClosed is true, the app crashes due to a segmentation fault
  @objc func handleAbout() {
    let viewController = AboutViewController()
    viewController.show()
  }

  @objc func handleCommandEntry() {
    self.inputViewController.show()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // TODO: stop all processes?
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return false }
}
