import Foundation

import QuickTermShared

let listener = NSXPCListener.service()

let serviceDelegate = ServiceDelegate()
listener.delegate = serviceDelegate;

listener.resume()
RunLoop.main.run()
