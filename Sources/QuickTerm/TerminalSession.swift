import Foundation
import os

import QuickTermShared

class TerminalSessionManager: ObservableObject {
  @Published var items: [TerminalSession] = []

  func append(_ session: TerminalSession) {
    objectWillChange.send()
    self.items.append(session)
  }

  func remove(_ session: TerminalSession) {
    objectWillChange.send()
    if let index = self.items.firstIndex(of: session) {
      self.items.remove(at: index)
    }
  }
}

class TerminalSession: Identifiable, ObservableObject, Equatable {
  typealias TerminatedCallback = (TerminalSession) -> ()
	var onTerminated: TerminatedCallback = { _ in }

  typealias StartedCallback = (TerminalSession) -> ()
	var onStarted: StartedCallback = { _ in }

  @Published private(set) var isRunning: Bool = false
  @Published private(set) var hasFinished: Bool = false
  @Published private(set) var exitCode: Int32? = nil
  /// Valid once hasFinished is true
  @Published private(set) var wasSuccessful: Bool = false

  public let id = UUID()

  private let process: Process!

  private let stdout: Pipe!
  private let outHandle: FileHandle!

  public let command: Command!
  @Published public var stdoutOutput = ""

  init(_ command: Command) {
    self.command = command

    logger.info("Creating session for command \(command.command)")
    var process = Process()
    process = Process()
    process.arguments = ["bash", "-c", command.command]
    process.currentDirectoryURL = command.workingDirectory
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    self.process = process
    logger.debug("Created process")

    logger.debug("Creating stdout pipe")
    self.stdout = Pipe()
    self.process.standardOutput = stdout
    self.outHandle = stdout.fileHandleForReading
    DispatchQueue.main.async {
      self.outHandle.waitForDataInBackgroundAndNotify()
    }

    logger.debug("Creating stdout observer")
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onDataAvailable),
      name: .NSFileHandleDataAvailable,
      object: self.outHandle
    )
  }

  public func start() throws {
    logger.info("Starting session \(self.id, privacy: .public)")
    if !self.isRunning && !self.hasFinished {
      self.isRunning = true
      self.process.terminationHandler = {
        _ in
        self.onTermination()
      }
      try self.process.run()
      self.onStarted(self)
    }
  }

  @objc private func onDataAvailable() {
    let data = self.outHandle.availableData

    if data.count > 0 {
      if let output = String(data: data, encoding: String.Encoding.utf8) {
        logger.debug("Got output data \(output)")
        self.stdoutOutput += output
      }
      outHandle.waitForDataInBackgroundAndNotify()
    } else {
      logger.debug("Received EOF")
    }
  }

  @objc private func onTermination() {
    logger.info("Process exited with code \(self.process.terminationStatus, privacy: .public)")
    logger.debug("Removing termination observer")
    self.exitCode = self.process.terminationStatus
    self.wasSuccessful = self.exitCode == 0
    self.hasFinished = true
    self.isRunning = false
    self.onTerminated(self)
  }

  static func ==(lhs: TerminalSession, rhs: TerminalSession) -> Bool {
    lhs.id == rhs.id
  }
}
