import Foundation

@objc public protocol CommandExecutorProtocol {
	/// Queue a command. Sends the command to the registered command
  /// executor.
	func queueCommand(_ configuration: CommandConfiguration)
}
