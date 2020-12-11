import Foundation
import os

import QuickTermShared

class TerminalSessionManager: ObservableObject {
  @Published var items: [TerminalSession] = []

  func append(_ session: TerminalSession) {
    objectWillChange.send()
    self.items.append(session)
  }
}

class TerminalSession: Identifiable, ObservableObject {
  public let id = UUID()

  private let process: Process!

  private let stdout: Pipe!
  private let outHandle: FileHandle!

  public let command: Command!
  @Published public var stdoutOutput = ""

  init(_ command: Command) {
    self.command = command

    logger.info("Creating session for command \(command.command)")
    self.process = Process()
    self.process.launchPath = "/usr/bin/env"
    self.process.arguments = ["bash", "-c", command.command]

    logger.debug("Creating stdout pipe")
    self.stdout = Pipe()
    self.process.standardOutput = stdout
    outHandle = stdout.fileHandleForReading
    outHandle.waitForDataInBackgroundAndNotify()

    logger.debug("Creating stdout observer")
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onDataAvailable),
      name: NSNotification.Name.NSFileHandleDataAvailable,
      object: outHandle
    )

    logger.debug("Creating termination observer")
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onTermination),
      name: Process.didTerminateNotification,
      object: outHandle
    )

    process.launch()
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
      logger.debug("No more data - removing stdout observer")
      NotificationCenter.default.removeObserver(
        self,
        name: NSNotification.Name.NSFileHandleDataAvailable,
        object: outHandle
      )
    }
  }

  @objc private func onTermination() {
    logger.debug("Removing termination observer")
    NotificationCenter.default.removeObserver(
      self,
      name: Process.didTerminateNotification,
      object: outHandle
    )
  }
}
