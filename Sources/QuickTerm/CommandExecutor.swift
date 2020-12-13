import Foundation

import QuickTermShared

class CommandExecutor: CommandExecutorProtocol {
	typealias ExecuteCommandCallback = (CommandConfiguration) -> ()
	var onExecuteCommand: ExecuteCommandCallback = { _ in }

	func queueCommand(_ configuration: CommandConfiguration) {
		logger.info("Got request to execute command, calling listeners")
		onExecuteCommand(configuration)
	}
}

class CommandExecutorDelegate: NSObject, NSXPCListenerDelegate {
	let executor: CommandExecutor

	init(executor: CommandExecutor) {
		self.executor = executor
	}

	func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
		logger.info("Accepting connection")
		let interface = NSXPCInterface(with: CommandExecutorProtocol.self)
		interface.setClasses([CommandConfiguration.self as AnyObject as! NSObject], for: #selector(CommandExecutorProtocol.queueCommand), argumentIndex: 0, ofReply: false)
		connection.exportedInterface = interface
		connection.exportedObject = self.executor
		connection.resume()
		return true
	}
}
