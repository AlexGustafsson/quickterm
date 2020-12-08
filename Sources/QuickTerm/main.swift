import AppKit
import os

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")

logger.log("Initiating application")
let app = NSApplication.shared
// Hide the application from the dock
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
logger.info("Starting application")
app.run()
logger.info("Application closed")
