import Foundation
import QuickTermShared
import os

class TerminalSessionManager: ObservableObject {
  @Published var sessions: [TerminalSession] = []

  private var shouldRemove: Bool = true
  private var sessionsForRemoval = Queue<TerminalSession>()

  func schedule(_ session: TerminalSession) {
    logger.info("Scheduling session \(session.id)")
    session.onActiveChanged = self.sessionActiveChanged

    let secondsToStart = Date().timeIntervalSince(session.configuration.startTime)
    DispatchQueue.main.asyncAfter(deadline: .now() + secondsToStart) {
      self.startSession(session)
    }
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
    if session.isActive {
      objectWillChange.send()
      self.sessions.append(session)
    } else {
      if self.shouldRemove {
        self.remove(session)
      } else {
        self.sessionsForRemoval.enqueue(session)
      }
    }
  }

  func remove(_ session: TerminalSession) {
    objectWillChange.send()
    if let index = self.sessions.firstIndex(of: session) {
      self.sessions.remove(at: index)
    }
  }

  func pauseRemoval() {
    self.shouldRemove = false
  }

  func resumeRemoval() {
    if !self.shouldRemove {
      // Remove all awaiting sessions
      while let session = self.sessionsForRemoval.dequeue() {
        self.remove(session)
      }
    }
    self.shouldRemove = true
  }
}
