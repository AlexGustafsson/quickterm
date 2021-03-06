import AppKit
import HotKey
import os
import QuickTermLibrary
import QuickTermShared
import SwiftUI

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/AppDelegate")

struct HistoryItem {
  let command: String
  let executionTime: Date
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var menu: QuickTermMenu?

  private let notificationViewController: NotificationViewController!

  private let sessionManager: TerminalSessionManager!

  private let delegate: CommandExecutorDelegate!
  private let executor: CommandExecutor!
  private let connection: NSXPCConnection!
  private let listener: NSXPCListener!

  private var hotKeys: [HotKey] = []

  private var configObserver: FileObserver!

  private var history: [HistoryItem] = []

  private var spotlightIsShowing: Bool = false

  override init() {
    self.sessionManager = TerminalSessionManager()
    self.notificationViewController = NotificationViewController(sessionManager: self.sessionManager)

    self.connection = NSXPCConnection(serviceName: "se.axgn.QuickTerm.Broker")
    self.connection.remoteObjectInterface = NSXPCInterface(with: BrokerProtocol.self)

    self.listener = NSXPCListener.anonymous()

    self.executor = CommandExecutor()

    self.delegate = CommandExecutorDelegate(executor: self.executor)
    self.listener.delegate = self.delegate
  }

  func applicationDidFinishLaunching(_: Notification) {
    self.menu = self.createMenu()

    self.notificationViewController.show()

    self.executor.onExecuteCommand = {
      configuration in
      let session = TerminalSession(configuration)
      self.sessionManager.schedule(session)
    }

    self.connection.interruptionHandler = {
      logger.info("Disconnected from broker (interrupted)")
    }

    self.connection.invalidationHandler = {
      logger.info("Disconnected from broker (invalidated)")
    }

    logger.info("Connecting to broker")
    self.listener.resume()
    self.connection.resume()

    let service =
      self.connection.synchronousRemoteObjectProxyWithErrorHandler {
        error in
        logger.error("Unable to get remote service: \(error.localizedDescription, privacy: .public)")
      } as? BrokerProtocol

    logger.info("Registering self as an executor")
    service!.registerCommandExecutor(client: self.listener.endpoint)

    self.configObserver = FileObserver(Config.filePath) {
      logger.info("Config file changed")
      do {
        try Config.load()
        logger.info("Config file reloaded")
        self.setupHotKeys()
      } catch {
        logger.error("Unable to reload configuration file: \(error.localizedDescription)")
        ConfigParseAlert(error: error).runModal()
      }
    }

    self.menu = self.createMenu()

    self.setupHotKeys()
  }

  private func setupHotKeys() {
    // Remove and unregister all hot keys
    self.hotKeys.removeAll()

    if let commandEntryHotKey = HotKey(keys: Config.current.hotKeys.showCommandEntry) {
      logger.info("Registering global hotkey")
      commandEntryHotKey.keyDownHandler = {
        self.promptUserForCommand()
      }
      self.hotKeys.append(commandEntryHotKey)
    } else {
      logger.error("Unable to bind hotkey \(Config.current.hotKeys.showCommandEntry, privacy: .public)")
      HotKeyParseAlert(hotKey: Config.current.hotKeys.showCommandEntry).runModal()
    }
  }

  private func createMenu() -> QuickTermMenu {
    let menu = QuickTermMenu()
    menu.onQuit = {
      NSApplication.shared.terminate(nil)
    }
    menu.onShowAbout = {
      let viewController = AboutViewController()
      viewController.show()
    }
    menu.onShowCommandEntry = {
      self.promptUserForCommand()
    }
    menu.onOpenConfigurationFile = {
      NSWorkspace.shared.open(Config.filePath)
    }
    return menu
  }

  func promptUserForCommand() {
    if self.spotlightIsShowing {
      logger.debug("User requested command prompt, but it's already shown")
      return
    }

    if let spotlight = Spotlight() {
      self.spotlightIsShowing = true
      let delegate = CommandSpotlightDelegate(spotlight, history: self.history)
      spotlight.delegate = delegate
      spotlight.show {
        command in

        let workingDirectory = Config.current.commandConfiguration.workingDirectory ?? FileManager.default
          .currentDirectoryPath
        let configuration = QuickTermShared.CommandConfiguration(
          workingDirectory: URL(fileURLWithPath: workingDirectory),
          command: command,
          shell: Config.current.commandConfiguration.shell,
          timeout: Config.current.commandConfiguration.timeout,
          keep: Config.current.commandConfiguration.keep,
          startTime: Date(),
          animate: Config.current.commandConfiguration.animate,
          waitForExit: Config.current.commandConfiguration.waitForExit,
          sourceBashProfile: Config.current.commandConfiguration.sourceBashProfile,
          delayAfterExit: Config.current.commandConfiguration.delayAfterExit
        )

        let session = TerminalSession(configuration)
        self.sessionManager.schedule(session)

        self.history.append(HistoryItem(command: command, executionTime: Date()))
      }
      self.spotlightIsShowing = false
    } else {
      logger.error("Unable to open prompt user for command")
    }
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { false }
}
