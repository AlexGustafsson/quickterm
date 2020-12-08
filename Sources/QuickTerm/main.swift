import AppKit
import ArgumentParser
import os

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
  // Hide the application from the dock
  app.setActivationPolicy(.accessory)
  let delegate = AppDelegate()
  app.delegate = delegate
  logger.info("Starting application")
  app.run()
  logger.info("Application closed")
}

func sendCommandToDaemon(workingDirectory: URL, command: String) throws {
  logger.info("Sending command to daemon")
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
    if command == "" {
      if let daemon = findDaemon() {
        logger.error("Tried to start daemon when it was already running")
        print("Daemon is already running")
        throw ExitCode(1)
      } else {
        print("Started daemon")
        try startApplication()
      }
    } else {
      let workingDirectory: URL = URL(string: FileManager.default.currentDirectoryPath)!
      try sendCommandToDaemon(workingDirectory: workingDirectory, command: command)
    }
  }
}

Quick.main()
