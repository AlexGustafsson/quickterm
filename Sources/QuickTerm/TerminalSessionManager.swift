import Foundation
import os

import QuickTermShared

class TerminalSessionManager: ObservableObject {
  @Published var sessions: [TerminalSession] = []

  func schedule(_ session: TerminalSession) {
    logger.info("Scheduling session \(session.id)")
    session.onActiveChanged = self.sessionActiveChanged

    let secondsToStart = Date().timeIntervalSince(session.configuration.startTime)
    DispatchQueue.main.asyncAfter(deadline: .now() + secondsToStart) {
      self.startSession(session)
    }

    objectWillChange.send()
    self.sessions.append(session)
  }

  private func startSession(_ session: TerminalSession) {
    do {
      logger.info("Starting session \(session.id)")
      try session.start()
    } catch {
      logger.error("Unable to start session \(session.id): \(error.localizedDescription)")
    }
  }

  private func sessionActiveChanged(_ session: TerminalSession) {
    objectWillChange.send()
  }
}
