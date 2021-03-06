import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/Utilities/FileObserver")

class FileObserver: NSObject, NSFilePresenter {
  lazy var presentedItemOperationQueue = OperationQueue.main
  var presentedItemURL: URL?

  typealias FileChangedCallback = () -> Void
  let onFileChanged: FileChangedCallback

  init(_ file: URL, callback: @escaping () -> Void) {
    self.presentedItemURL = file
    self.onFileChanged = callback
    super.init()
    NSFileCoordinator.addFilePresenter(self)
  }

  func presentedItemDidChange() {
    logger.debug("File changed")
    self.onFileChanged()
  }
}
