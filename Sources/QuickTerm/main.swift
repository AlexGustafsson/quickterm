import os
import AppKit

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")

logger.log("Initiating application")
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
logger.info("Starting application")
app.run()
logger.info("Application closed")
