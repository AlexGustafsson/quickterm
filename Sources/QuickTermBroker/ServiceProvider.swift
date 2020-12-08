import Foundation

import QuickTermShared

@objc class ServiceProvider: NSObject, ServiceProviderProtocol {
  func test(withReply reply: @escaping (String) -> Void) {
    reply("Hello, World!")
  }
}
