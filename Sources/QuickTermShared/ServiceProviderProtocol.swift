import Foundation

@objc(ServiceProviderProtocol) public protocol ServiceProviderProtocol {
  /// Registers the command executor. The command executor will receive
  /// all the executed commands. Overwrites any previously registered executor.
  func registerCommandExecutor(client endpoint: NSXPCListenerEndpoint)

  /// Execute a command. Sends the command to the registered command
  /// executor. Throws if no executor is registered.
  func executeCommand(_ command: Command)
}
