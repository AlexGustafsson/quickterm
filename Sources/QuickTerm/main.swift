import AppKit
import ArgumentParser
import Foundation
import os

import QuickTermShared

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")

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
    print("Started daemon")
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

func sendCommandToDaemon(workingDirectory: URL, command: String) throws {
  logger.debug("Establishing broker connection")
  let connection = NSXPCConnection(serviceName: "se.axgn.QuickTerm.Broker")
  connection.remoteObjectInterface = NSXPCInterface(with: BrokerProtocol.self)

  connection.interruptionHandler = {
    print("Disconnected from broker (interrupted)")
    // TODO: Exit(1)
  };

  connection.invalidationHandler = {
    print("Disconnected from broker (invalidated)")
    // TODO: Exit(1)
  };

  connection.resume()
  logger.debug("Connected to broker")

  let service = connection.synchronousRemoteObjectProxyWithErrorHandler {
    error in
    logger.error("\(error.localizedDescription, privacy: .public)")
    print("Received error:", error)

  } as? BrokerProtocol
  logger.debug("Got service protocol")

  logger.info("Sending request to execute command")
  service!.queueCommand(CommandConfiguration(workingDirectory: workingDirectory, command: command))

  // TODO: Don't run forever, just until the above line succeeds
}

struct Quick: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Run a command in a seperate window")

  @Option(help: "Number of seconds to wait after a command is done before closing the window")
  var closeDelay: Double = 2

  @Flag(help: "Whether or not the window should stay until the command finishes or is closed")
  var stay: Bool = false

  // Add an explicit help flag so that the help flag works even though
  // uncoditional remaining parsing is used for the arguments below
  @Flag(name: .shortAndLong, help: .hidden)
  var help: Bool = false

  @Argument(parsing: .unconditionalRemaining, help: ArgumentHelp("Command to execute", valueName: "command"))
  var arguments: [String] = []

  func validate() throws {
    if help && arguments.count == 0{
      throw CleanExit.helpRequest()
    }

    guard closeDelay >= 0 else {
      throw ValidationError("'close-delay' must be larger than or equal to 0")
    }
  }

  func run() throws {
    let command = arguments.joined(separator: " ")
    if let daemon = findDaemon() {
      if command == "" {
        logger.error("Tried to start daemon when it was already running")
        print("Daemon is already running")
        throw ExitCode(1)
      } else {
        let workingDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        try sendCommandToDaemon(workingDirectory: workingDirectory, command: command)
      }
    } else {
      if command == "" {
        try startApplication()
      } else {
        print("Daemon is not running")
        throw ExitCode(1)
      }
    }
  }
}

Quick.main()
