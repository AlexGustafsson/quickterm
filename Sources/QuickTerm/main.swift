import AppKit
import ArgumentParser
import Foundation
import os
import QuickTermShared

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/Main")
private var stderr = FileHandle.standardError

func daemonExists() -> Bool {
  let bundleIdentifier = Bundle.main.bundleIdentifier!
  let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
  for app in apps {
    if app != NSRunningApplication.current {
      return true
    }
  }

  return false
}

func startApplication(isInTTY: Bool) throws {
  // Start the app via launchd instead if started from a terminal
  // Basically "daemonizes" the app
  if isInTTY {
    let bundlePath = Bundle.main.bundlePath
    NSWorkspace.shared.open(URL(fileURLWithPath: bundlePath))
    print("Started daemon", to: &stderr)
    return
  }

  logger.info("Initiating application")
  let app = NSApplication.shared

  let appDelegate = AppDelegate()
  app.delegate = appDelegate

  logger.info("Starting application")
  app.run()

  logger.info("Application closed")
}

func sendCommandToDaemon(_ commandConfiguration: QuickTermShared.CommandConfiguration) throws {
  logger.debug("Establishing broker connection")
  let connection = NSXPCConnection(serviceName: "se.axgn.QuickTerm.Broker")
  connection.remoteObjectInterface = NSXPCInterface(with: BrokerProtocol.self)

  connection.interruptionHandler = {
    print("Disconnected from broker (interrupted)", to: &stderr)
    exit(1)
  }

  connection.invalidationHandler = {
    print("Disconnected from broker (invalidated)", to: &stderr)
    exit(1)
  }

  connection.resume()
  logger.debug("Connected to broker")

  let service =
    connection.synchronousRemoteObjectProxyWithErrorHandler {
      error in
      logger.error("\(error.localizedDescription, privacy: .public)")
      print("Received error:", error, to: &stderr)
      exit(1)
    } as? BrokerProtocol
  logger.debug("Got service protocol")

  logger.info("Sending request to execute command")
  service!.queueCommand(commandConfiguration, withReply: {
    wasSuccessful in
    logger.info("Request was \(wasSuccessful ? "successful" : "unsuccessful", privacy: .public)")
    if !wasSuccessful {
      print("Unable to schedule command", to: &stderr)
      exit(1)
    }
  })
}

struct Quick: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Run a command in a separate window")

  @Flag(
    help:
    "Whether or not the output should be animated as it's received. Does not work with --wait-for-exit as the output is fully available when shown"
  )
  var animate: Bool = Config.current.commandConfiguration.animate

  @Option(help: "The shell to use")
  var shell: String = Config.current.commandConfiguration.shell

  @Option(help: "The number of seconds to wait before terminating the command")
  var timeout: Double = Config.current.commandConfiguration.timeout

  @Flag(help: "Whether or not the window should stay until the command finishes or is closed")
  var keep: Bool = Config.current.commandConfiguration.keep

  @Flag(help: "Whether or not to wait for the command to exit before presenting the view")
  var waitForExit: Bool = Config.current.commandConfiguration.waitForExit

  @Flag(help: "Don't source `~/.bash_profile` before executing the command. Applicable only when using Bash as shell")
  var noBashProfile: Bool = !Config.current.commandConfiguration.sourceBashProfile

  @Option(help: "The number of seconds to wait after exit before closing the notification. Not used if keep is true")
  var delayAfterExit: Double = Config.current.commandConfiguration.delayAfterExit

  @Option(help: "The working directory to run the command in. Defaults to the current working directory")
  var workingDirectory: String = FileManager.default.currentDirectoryPath

  @Flag(help: "Dump the command configuration as JSON. Will be used if the command is to be ran")
  var dump: Bool = false

  @Flag(help: "Print the path to the config file")
  var printConfigPath: Bool = false

  // Add an explicit help flag so that the help flag works even though
  // uncoditional remaining parsing is used for the arguments below
  @Flag(name: .shortAndLong, help: .hidden)
  var help: Bool = false

  @Argument(
    parsing: .unconditionalRemaining,
    help: ArgumentHelp("Command to execute. If none is given, starts the daemon instead", valueName: "command")
  )
  var arguments: [String] = []

  func validate() throws {
    if self.help, self.arguments.isEmpty {
      throw CleanExit.helpRequest()
    }

    if self.printConfigPath, self.arguments.isEmpty {
      var configFile = FileManager.default.homeDirectoryForCurrentUser
      configFile.appendPathComponent(".config", isDirectory: true)
      configFile.appendPathComponent("quickterm", isDirectory: true)
      configFile.appendPathComponent("config.yml")
      print(configFile.path)
      throw ExitCode(0)
    }

    guard self.timeout >= 0 else {
      throw ValidationError("'timeout' must be larger than or equal to 0")
    }

    guard self.delayAfterExit >= 0 else {
      throw ValidationError("'delay-after-exit' must be larger than or equal to 0")
    }
  }

  func run() throws {
    let command = self.arguments.joined(separator: " ")
    if daemonExists() {
      if command == "" {
        logger.error("Tried to start daemon when it was already running")
        print("Daemon is already running", to: &stderr)
        throw ExitCode(1)
      } else {
        let commandConfiguration = QuickTermShared.CommandConfiguration(
          workingDirectory: URL(fileURLWithPath: self.workingDirectory),
          command: command,
          shell: self.shell,
          timeout: self.timeout,
          keep: self.keep,
          startTime: Date(),
          animate: self.animate,
          waitForExit: self.waitForExit,
          sourceBashProfile: !self.noBashProfile,
          delayAfterExit: self.delayAfterExit
        )
        if self.dump {
          let json = try commandConfiguration.dump()
          print(json)
        } else {
          try sendCommandToDaemon(commandConfiguration)
        }
      }
    } else {
      if command == "" {
        try startApplication(isInTTY: isatty(0) == 1)
      } else {
        print("Daemon is not running", to: &stderr)
        throw ExitCode(1)
      }
    }
  }
}

do {
  try Config.dump()
} catch {
  logger.error("Unable to create configuration file: \(error.localizedDescription)")
}

do {
  try Config.load()
} catch {
  logger.error("Unable to load configuration file: \(error.localizedDescription)")
  if isatty(0) == 1 {
    print("Unable to load configuration file: \(error.localizedDescription) Using defaults.", to: &stderr)
  } else {
    ConfigParseAlert(error: error).runModal()
  }
}

Quick.main()
