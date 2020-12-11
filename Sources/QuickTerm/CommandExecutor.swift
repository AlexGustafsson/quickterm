import Foundation

import QuickTermShared

class CommandExecutor: CommandExecutorProtocol {
	typealias ExecuteCommandCallback = (Command) -> ()
	var onExecuteCommand: ExecuteCommandCallback = { _ in }

	func executeCommand(_ command: Command) {
		logger.info("Got request to execute command, calling listeners")
		onExecuteCommand(command)
	}
}

class CommandExecutorDelegate: NSObject, NSXPCListenerDelegate {
	let executor: CommandExecutor

	init(executor: CommandExecutor) {
		self.executor = executor
	}

	func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
		let interface = NSXPCInterface(with: CommandExecutorProtocol.self)
		interface.setClasses([Command.self as AnyObject as! NSObject], for: #selector(CommandExecutorProtocol.executeCommand), argumentIndex: 0, ofReply: false)
		connection.exportedInterface = interface
		connection.exportedObject = self.executor
		connection.resume()
		return true
	}
}
