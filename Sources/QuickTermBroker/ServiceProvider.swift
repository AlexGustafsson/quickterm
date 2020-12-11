import Foundation

import QuickTermShared

@objc class ServiceProvider: NSObject, ServiceProviderProtocol {
  // TODO: Lock?
  private var executorConnection: NSXPCConnection? = nil

  func registerCommandExecutor(client endpoint: NSXPCListenerEndpoint) {
    logger.info("Registering a command executor")
		let connection = NSXPCConnection(listenerEndpoint: endpoint)

    // Configure message encoding
		let interface = NSXPCInterface(with: CommandExecutorProtocol.self)
		interface.setClasses([Command.self as AnyObject as! NSObject], for: #selector(CommandExecutorProtocol.executeCommand), argumentIndex: 0, ofReply: false)
		connection.remoteObjectInterface = interface

    // Close any existing connection
    if self.executorConnection != nil {
      logger.info("Closing existing executor connection")
      self.executorConnection?.invalidate()
      self.executorConnection = nil
    }

    self.executorConnection = connection

    // Start communication
		connection.resume()
    logger.info("Registered command executor")
	}

  /// Execute a command. Sends the command to the registered command
  /// executor. Throws if no executor is registered.
  func executeCommand(_ command: Command) {
    if self.executorConnection == nil {
      logger.error("No executor registered - command will not be executed")
      return
    }

    logger.info("Requesting command execution from executor")
    (self.executorConnection as? CommandExecutorProtocol)?.executeCommand(command)
	}
}
