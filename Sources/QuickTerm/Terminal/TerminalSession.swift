import Foundation
import os
import QuickTermShared

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/Terminal/TerminalSession")

class TerminalSession: Identifiable, ObservableObject, Equatable {
  typealias ActiveChangedCallback = (TerminalSession) -> Void
  var onActiveChanged: ActiveChangedCallback = { _ in }

  @Published private(set) var isRunning: Bool = false
  @Published private(set) var hasFinished: Bool = false
  @Published private(set) var exitCode: Int32? = nil
  /// Valid once hasFinished is true
  @Published private(set) var wasSuccessful: Bool = false
  // Whether or not the session is invalidated. That is, if it is no longer in
  // use (process has exited, delay has been passed and so on)
  @Published private(set) var isActive: Bool = false
  @Published private(set) var exitTime: Date? = nil

  public let id = UUID()

  private let process: Process!

  private var stdout: Pipe!
  private var stdoutHandle: FileHandle!

  private var stderr: Pipe!
  private var stderrHandle: FileHandle!

  public let configuration: CommandConfiguration!
  @Published public var output = ""
  @Published public var stdoutOutput = ""
  @Published public var stderrOutput = ""

  init(_ configuration: CommandConfiguration) {
    self.configuration = configuration

    logger.info("Creating session for command \(configuration.command)")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    var command: String = configuration.command
    if configuration.shell == "bash", configuration.sourceBashProfile {
      command = "shopt -s expand_aliases;source ~/.bash_profile\n" + command
    }
    process.arguments = [configuration.shell, "-c", command]
    process.currentDirectoryURL = configuration.workingDirectory
    self.process = process
    logger.debug("Created process")

    logger.debug("Creating stdout pipe")
    self.stdout = Pipe()
    self.process.standardOutput = self.stdout
    self.stdoutHandle = self.stdout.fileHandleForReading
    DispatchQueue.main.async {
      self.stdoutHandle.waitForDataInBackgroundAndNotify()
    }

    logger.debug("Creating stdout observer")
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onStdoutDataAvailable),
      name: .NSFileHandleDataAvailable,
      object: self.stdoutHandle
    )

    logger.debug("Creating stderr pipe")
    self.stderr = Pipe()
    self.process.standardError = self.stderr
    self.stderrHandle = self.stderr.fileHandleForReading
    DispatchQueue.main.async {
      self.stderrHandle.waitForDataInBackgroundAndNotify()
    }

    logger.debug("Creating stderr observer")
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onStderrDataAvailable),
      name: .NSFileHandleDataAvailable,
      object: self.stderrHandle
    )
  }

  public func start() throws {
    logger.info("Starting session \(self.id, privacy: .public)")
    if !self.isRunning, !self.hasFinished {
      self.isRunning = true
      self.process.terminationHandler = {
        _ in
        self.onTermination()
      }
      try self.process.run()
      if !self.configuration.waitForExit {
        self.isActive = true
        self.onActiveChanged(self)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + self.configuration.timeout) {
        self.terminate()
      }
    }
  }

  public func terminate() {
    logger.info("Terminating session \(self.id, privacy: .public)")
    // Does nothing if it's already terminated
    self.process.terminate()
  }

  @objc private func onStdoutDataAvailable() {
    let data = self.stdoutHandle.availableData

    if !data.isEmpty {
      if let output = String(data: data, encoding: String.Encoding.utf8) {
        logger.debug("Got output data \(output)")
        self.stdoutOutput += output
        self.output += output
      }
      self.stdoutHandle.waitForDataInBackgroundAndNotify()
    } else {
      logger.debug("Received EOF")
    }
  }

  @objc private func onStderrDataAvailable() {
    let data = self.stderrHandle.availableData

    if !data.isEmpty {
      if let output = String(data: data, encoding: String.Encoding.utf8) {
        logger.debug("Got output data \(output)")
        self.stderrOutput += output
        self.output += output
      }
      self.stderrHandle.waitForDataInBackgroundAndNotify()
    } else {
      logger.debug("Received EOF")
    }
  }

  private func onTermination() {
    logger.info("Process exited with code \(self.process.terminationStatus, privacy: .public)")
    self.exitCode = self.process.terminationStatus
    self.wasSuccessful = self.exitCode == 0
    self.hasFinished = true
    self.isRunning = false
    if self.configuration.waitForExit {
      self.isActive = true
      self.onActiveChanged(self)
    }
    self.exitTime = Date()
    DispatchQueue.main.asyncAfter(deadline: .now() + self.configuration.delayAfterExit) {
      logger.info("Session \(self.id, privacy: .public) invalidated")
      self.objectWillChange.send()
      self.isActive = false
      self.onActiveChanged(self)
    }
  }

  static func == (lhs: TerminalSession, rhs: TerminalSession) -> Bool {
    lhs.id == rhs.id
  }
}
