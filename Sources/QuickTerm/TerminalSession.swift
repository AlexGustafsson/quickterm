import os
import Foundation

class TerminalSessionManager: ObservableObject {
  @Published var items: [TerminalSession] = []

  func append(_ session: TerminalSession) {
    objectWillChange.send()
    self.items.append(session)
  }
}

class TerminalSession: Identifiable, ObservableObject {
  let id = UUID()

  var process: Process!

  var stdout: Pipe!
  var stdoutObserver : NSObjectProtocol!
  var terminationObserver : NSObjectProtocol!

  var command: String!
  @Published var stdoutOutput = ""

  init(_ command: String) {
    self.command = command

    logger.info("Creating session for command \(command)")
    self.process = Process()
    self.process.launchPath = "/usr/bin/env"
    self.process.arguments = ["bash", "-c", command]

    logger.debug("Creating stdout pipe")
    self.stdout = Pipe()
    self.process.standardOutput = stdout
    let outHandle = stdout.fileHandleForReading
    outHandle.waitForDataInBackgroundAndNotify()

    logger.debug("Creating stdout observer")
    self.stdoutObserver = NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSFileHandleDataAvailable,
      object: outHandle, queue: nil
    ) {
      notification -> Void in
      let data = outHandle.availableData

      if data.count > 0 {
        if let output = String(data: data, encoding: String.Encoding.utf8) {
          logger.debug("Got output data \(output)")
          self.stdoutOutput += output
        }
        outHandle.waitForDataInBackgroundAndNotify()
      } else {
        logger.debug("No more data - removing stdout observer")
        NotificationCenter.default.removeObserver(self.stdoutObserver as Any)
      }
    }

    logger.debug("Creating termination observer")
    terminationObserver = NotificationCenter.default.addObserver(
      forName: Process.didTerminateNotification,
      object: process, queue: nil
    ) {
      notification -> Void in
      logger.debug("Removing termination observer")
      NotificationCenter.default.removeObserver(self.terminationObserver as Any)
    }

    process.launch()
  }
}
