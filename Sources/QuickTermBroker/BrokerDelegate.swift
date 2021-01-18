import Foundation
import os
import QuickTermShared

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Broker/BrokerDelegate")

class BrokerDelegate: NSObject, NSXPCListenerDelegate {
  private let broker: Broker

  init(_ broker: Broker) {
    self.broker = broker
  }

  func listener(_: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    logger.info("Accepting connection")
    newConnection.exportedInterface = NSXPCInterface(with: BrokerProtocol.self)
    newConnection.exportedObject = self.broker
    newConnection.resume()
    return true
  }
}
