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
  // TODO: start the daemon in background so this thread can do other things
  logger.log("Initiating application")
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
  connection.remoteObjectInterface = NSXPCInterface(with: ServiceProviderProtocol.self)

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

  } as? ServiceProviderProtocol
  logger.debug("Got service protocol")

  logger.info("Sending request to execute command")
  service!.executeCommand(Command(workingDirectory: workingDirectory, command: command))

  // TODO: Don't run forever, just until the above line succeeds
  RunLoop.main.run()
}

struct Quick: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Run a command in a seperate window")

  @Argument(help: ArgumentHelp("Command to execute", valueName: "command"))
  var arguments: [String] = []

  @Option(help: "Number of seconds to wait after a command is done before closing the window")
  var closeDelay: Double = 2

  @Flag(help: "Whether or not the window should stay until the command finishes or is closed")
  var stay: Bool = false

  func validate() throws {
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
        let workingDirectory: URL = URL(string: FileManager.default.currentDirectoryPath)!
        try sendCommandToDaemon(workingDirectory: workingDirectory, command: command)
      }
    } else {
      if command == "" {
        try startApplication()
        print("Started daemon")
      } else {
        print("Daemon is not running")
        throw ExitCode(1)
      }
    }
  }
}

Quick.main()
