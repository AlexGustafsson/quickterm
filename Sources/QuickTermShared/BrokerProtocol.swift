import Foundation

@objc public protocol BrokerProtocol {
  typealias ReplyCallback = (Bool) -> Void

  /// Registers the command executor. The command executor will receive
  /// all the executed commands. Overwrites any previously registered executor.
  func registerCommandExecutor(client endpoint: NSXPCListenerEndpoint)

  /// Queue a command. Sends the command to the registered command
  /// executor.
  func queueCommand(_ configuration: CommandConfiguration, withReply reply: @escaping ReplyCallback)
}
