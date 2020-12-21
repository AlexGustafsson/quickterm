import AppKit
import ArgumentParser
import Foundation
import os

import QuickTermShared

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")
var stderr = FileHandle.standardError

func findDaemon() -> NSRunningApplication? {
  let bundleIdentifier = Bundle.main.bundleIdentifier!
  let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
  for app in apps {
    if app != NSRunningApplication.current {
      return app
    }
  }

  return nil
}

func startApplication() throws {
  // Start the app via launchd instead if started from a terminal
  // Basically "daemonizes" the app
  let isInTTY = isatty(0) == 1
  if isInTTY {
    let bundlePath = Bundle.main.bundlePath
    NSWorkspace.shared.open(URL(fileURLWithPath: bundlePath))
    print("Started daemon", to:&stderr)
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
    print("Disconnected from broker (interrupted)", to:&stderr)
    // TODO: Exit(1)
  };

  connection.invalidationHandler = {
    print("Disconnected from broker (invalidated)", to:&stderr)
    // TODO: Exit(1)
  };

  connection.resume()
  logger.debug("Connected to broker")

  let service = connection.synchronousRemoteObjectProxyWithErrorHandler {
    error in
    logger.error("\(error.localizedDescription, privacy: .public)")
    print("Received error:", error, to:&stderr)

  } as? BrokerProtocol
  logger.debug("Got service protocol")

  logger.info("Sending request to execute command")
  service!.queueCommand(commandConfiguration)

  // TODO: Don't run forever, just until the above line succeeds
}

struct Quick: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Run a command in a separate window")

  @Flag(help: "Whether or not the output should be animated as it's received. Does not work with --wait-for-exit as the output is fully available when shown")
  var animate: Bool = false

  @Option(help: "The shell to use")
  var shell: String = "bash"

  @Option(help: "The number of seconds to wait before terminating the command")
  var timeout: Double = 5.0

  @Flag(help: "Whether or not the window should stay until the command finishes or is closed")
  var keep: Bool = false

  @Flag(help: "Whether or not to wait for the command to exit before presenting the view")
  var waitForExit: Bool = false

  @Flag(help: "Dump the command configuration as JSON. Will be used if the command is to be ran")
  var dump: Bool = false


  // Add an explicit help flag so that the help flag works even though
  // uncoditional remaining parsing is used for the arguments below
  @Flag(name: .shortAndLong, help: .hidden)
  var help: Bool = false

  @Argument(parsing: .unconditionalRemaining, help: ArgumentHelp("Command to execute. If none is given, starts the daemon instead", valueName: "command"))
  var arguments: [String] = []

  func validate() throws {
    if help && arguments.count == 0 {
      throw CleanExit.helpRequest()
    }

    guard timeout >= 0 else {
      throw ValidationError("'timeout' must be larger than or equal to 0")
    }
  }

  func run() throws {
    let command = arguments.joined(separator: " ")
    if let daemon = findDaemon() {
      if command == "" {
        logger.error("Tried to start daemon when it was already running")
        print("Daemon is already running", to:&stderr)
        throw ExitCode(1)
      } else {
        let workingDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let commandConfiguration = QuickTermShared.CommandConfiguration(
          workingDirectory: workingDirectory,
          command: command,
          shell: shell,
          timeout: timeout,
          keep: keep,
          animate: animate,
          waitForExit: waitForExit
        )
        if dump {
          let json = try commandConfiguration.dump()
          print(json)
        } else {
          try sendCommandToDaemon(commandConfiguration)
        }
      }
    } else {
      if command == "" {
        try startApplication()
      } else {
        print("Daemon is not running", to:&stderr)
        throw ExitCode(1)
      }
    }
  }
}

Quick.main()
