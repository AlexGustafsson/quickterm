import Foundation

import QuickTermShared

class ServiceDelegate : NSObject, NSXPCListenerDelegate {
  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    newConnection.exportedInterface = NSXPCInterface(with: ServiceProviderProtocol.self)

    let exportedObject = ServiceProvider()
    newConnection.exportedObject = exportedObject
    newConnection.resume()
    return true
  }
}
