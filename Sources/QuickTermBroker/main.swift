import Foundation
import os

import QuickTermShared

logger.debug("Establishing broker listener")
let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "broker")

let listener = NSXPCListener.service()

let serviceDelegate = ServiceDelegate()
listener.delegate = serviceDelegate;

logger.info("Listening")
listener.resume()
RunLoop.main.run()
