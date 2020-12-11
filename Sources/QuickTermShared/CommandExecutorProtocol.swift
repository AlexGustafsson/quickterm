import Foundation

@objc(CommandExecutorProtocol) public protocol CommandExecutorProtocol {
	func executeCommand(_ command: Command)
}
