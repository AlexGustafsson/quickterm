import AppKit
import HotKey
import QuickTermShared
import SwiftUI

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

  private var configObserver: FileObserver!

  override init() {
    self.sessionManager = TerminalSessionManager()
    self.notificationViewController = NotificationViewController(sessionManager: self.sessionManager)
    self.inputViewController = InputViewController()

    self.connection = NSXPCConnection(serviceName: "se.axgn.QuickTerm.Broker")
    self.connection.remoteObjectInterface = NSXPCInterface(with: BrokerProtocol.self)

    self.listener = NSXPCListener.anonymous()

    self.executor = CommandExecutor()

    self.delegate = CommandExecutorDelegate(executor: executor)
    self.listener.delegate = self.delegate

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
    menu.addItem(
      NSMenuItem(
        title: "Show Command Entry",
        action: #selector(self.handleCommandEntry),
        keyEquivalent: "t",
        keyEquivalentModifierMask: [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.option]
      )
    )
    menu.addItem(NSMenuItem.separator())
    menu.addItem(
      NSMenuItem(
        title: "Open Configuration File",
        action: #selector(self.openConfigurationFile),
        keyEquivalent: ""
      )
    )
    menu.addItem(
      NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
    )

    statusItem.menu = menu

    executor.onExecuteCommand = {
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
      self.handleCommandEntry()
    }

    self.inputViewController.onExecuteCommand = {
      command in
      let workingDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
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
      } catch let error {
        logger.error("Unable to reload configuration file: \(error.localizedDescription)")
        let alert = NSAlert()
        alert.messageText = "Unable to load configuration file"
        alert.informativeText = "Unable to load configuration file: \(error.localizedDescription) The built-in defaults will be used instead."
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        alert.runModal()
      }
    }
  }

  @objc func handleAbout() {
    let viewController = AboutViewController()
    viewController.show()
  }

  @objc func handleCommandEntry() {
    self.inputViewController.show()
  }

  @objc func openConfigurationFile() {
    var configFile = FileManager.default.homeDirectoryForCurrentUser
    configFile.appendPathComponent(".config", isDirectory: true)
    configFile.appendPathComponent("quickterm", isDirectory: true)
    configFile.appendPathComponent("config.yml")
    NSWorkspace.shared.openFile(configFile.path)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return false }
}
