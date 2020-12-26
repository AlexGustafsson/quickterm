import Foundation
import os
import QuickTermShared

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "broker")

logger.debug("Creating broker listener")
let listener = NSXPCListener.service()

let broker = Broker()
let delegate = BrokerDelegate(broker)
listener.delegate = delegate

logger.info("Listening")
listener.resume()
RunLoop.main.run()
