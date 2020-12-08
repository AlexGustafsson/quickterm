import Foundation

@objc(ServiceProviderProtocol) public protocol ServiceProviderProtocol {
  func test(withReply reply: @escaping (String) -> Void)
}
