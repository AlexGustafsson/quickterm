import Foundation

@objc public protocol CommandExecutorProtocol {
	func executeCommand(_ command: Command)
}
