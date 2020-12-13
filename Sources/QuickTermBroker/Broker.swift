import Foundation

import QuickTermShared

@objc class Broker: NSObject, BrokerProtocol {
  // TODO: Lock?
  private var executorConnection: NSXPCConnection? = nil
  private var executor: CommandExecutorProtocol? = nil

  func registerCommandExecutor(client endpoint: NSXPCListenerEndpoint) {
    logger.info("Registering a command executor")
		let connection = NSXPCConnection(listenerEndpoint: endpoint)

    // Configure message encoding
		let interface = NSXPCInterface(with: CommandExecutorProtocol.self)
		interface.setClasses([CommandConfiguration.self as AnyObject as! NSObject], for: #selector(CommandExecutorProtocol.queueCommand), argumentIndex: 0, ofReply: false)
		connection.remoteObjectInterface = interface

    if let executor = connection.remoteObjectProxy as? CommandExecutorProtocol {
      // Close any existing connection
      if self.executorConnection != nil {
        logger.info("Closing existing executor connection")
        self.executorConnection?.invalidate()
        self.executorConnection = nil
        self.executor = nil
      }

      self.executorConnection = connection
      self.executor = executor

      // An interruption handler that is called if the remote process exits or crashes.
      self.executorConnection?.interruptionHandler = {
        logger.info("Disconnected from executor (interrupted)")
        self.executorConnection = nil
        self.executor = nil
      };

      // An invalidation handler that is called if the connection can not be formed or the connection has terminated and may not be re-established.
      self.executorConnection?.invalidationHandler = {
        logger.info("Disconnected from executor (invalidated)")
        self.executorConnection = nil
        self.executor = nil
      };

      // Start communication
  		connection.resume()
      logger.info("Registered command executor")
		} else {
      logger.error("Got connection from non-conforming client")
      connection.invalidate()
    }
	}

  func queueCommand(_ configuration: CommandConfiguration) {
    if self.executor == nil {
      // TODO: This should be able to be handled with a client protocol,
      // execute a "withError" or something
      logger.error("No executor registered - command will not be executed")
      return
    }

    logger.info("Requesting command execution from executor")
    self.executor?.queueCommand(configuration)
    logger.info("Request sent")
	}
}
