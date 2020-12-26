import AppKit
import HotKey
import QuickTermShared
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  private var menu: QuickTermMenu?

  private let notificationViewController: NotificationViewController!
  private let inputViewController: InputViewController!

  private let sessionManager: TerminalSessionManager!

  private let delegate: CommandExecutorDelegate!
  private let executor: CommandExecutor!
  private let connection: NSXPCConnection!
  private let listener: NSXPCListener!

  private let commandEntryHotKey: HotKey!

  private var configObserver: FileObserver!

  override init() {
    self.sessionManager = TerminalSessionManager()
    self.notificationViewController = NotificationViewController(sessionManager: self.sessionManager)
    self.inputViewController = InputViewController()

    self.connection = NSXPCConnection(serviceName: "se.axgn.QuickTerm.Broker")
    self.connection.remoteObjectInterface = NSXPCInterface(with: BrokerProtocol.self)

    self.listener = NSXPCListener.anonymous()

    self.executor = CommandExecutor()

    self.delegate = CommandExecutorDelegate(executor: self.executor)
    self.listener.delegate = self.delegate

    self.commandEntryHotKey = HotKey(key: .t, modifiers: [.command, .option])
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

    logger.info("Registering global hotkey")

    self.commandEntryHotKey.keyDownHandler = {
      self.inputViewController.show()
    }

    self.inputViewController.onExecuteCommand = {
      command in
      let workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      let configuration = QuickTermShared.CommandConfiguration(
        workingDirectory: workingDirectory,
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
    }

    var configFile = FileManager.default.homeDirectoryForCurrentUser
    configFile.appendPathComponent(".config", isDirectory: true)
    configFile.appendPathComponent("quickterm", isDirectory: true)
    configFile.appendPathComponent("config.yml", isDirectory: false)
    self.configObserver = FileObserver(configFile) {
      logger.info("Config file changed")
      do {
        try Config.load()
        logger.info("Config file reloaded")
      } catch {
        logger.error("Unable to reload configuration file: \(error.localizedDescription)")
        let alert = NSAlert()
        alert.messageText = "Unable to load configuration file"
        alert
          .informativeText =
          "Unable to load configuration file: \(error.localizedDescription) The built-in defaults will be used instead."
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        alert.runModal()
      }
    }

    self.menu = self.createMenu()
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
      self.inputViewController.show()
    }
    menu.onOpenConfigurationFile = {
      var configFile = FileManager.default.homeDirectoryForCurrentUser
      configFile.appendPathComponent(".config", isDirectory: true)
      configFile.appendPathComponent("quickterm", isDirectory: true)
      configFile.appendPathComponent("config.yml")
      NSWorkspace.shared.openFile(configFile.path)
    }
    return menu
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { false }
}
