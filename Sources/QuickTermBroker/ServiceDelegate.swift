import Foundation

import QuickTermShared

class ServiceDelegate : NSObject, NSXPCListenerDelegate {
  private let service = ServiceProvider()

  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    logger.info("Accepting connection")
    newConnection.exportedInterface = NSXPCInterface(with: ServiceProviderProtocol.self)
    newConnection.exportedObject = service
    newConnection.resume()
    return true
  }
}
