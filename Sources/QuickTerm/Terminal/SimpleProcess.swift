import Foundation
import os

class SimpleProcess {
  let process: Process
  let stdout: Pipe
  let stdoutHandle: FileHandle

  typealias ExitCallback = (String) -> Void
  var onExit: ExitCallback = { _ in }

  private var output = ""

  init(command: String) {
    self.process = Process()
    self.process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

    var shellCommand = command
    if Config.current.commandConfiguration.sourceBashProfile {
      shellCommand = "shopt -s expand_aliases;source ~/.bash_profile\n" + command
    }
    self.process.arguments = ["bash", "-c", shellCommand]

    self.stdout = Pipe()
    self.process.standardOutput = self.stdout

    self.stdoutHandle = self.stdout.fileHandleForReading
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onStdoutDataAvailable),
      name: .NSFileHandleDataAvailable,
      object: self.stdoutHandle
    )

    DispatchQueue.main.async {
      self.stdoutHandle.waitForDataInBackgroundAndNotify()
    }
  }

  @objc private func onStdoutDataAvailable() {
    let data = self.stdoutHandle.availableData

    if !data.isEmpty {
      if let output = String(data: data, encoding: String.Encoding.utf8) {
        logger.info("Got data from simple process")
        self.output += output
      }
      self.stdoutHandle.waitForDataInBackgroundAndNotify()
    } else {
      logger.info("Simple process closed stdout")
    }
  }

  public func run(onExit: @escaping ExitCallback) throws {
    logger.info("Starting simple process")
    self.onExit = onExit
    self.process.terminationHandler = {
      _ in
      logger.info("Simple process terminated")
      self.onExit(self.output)
    }
    try self.process.run()
  }
}
