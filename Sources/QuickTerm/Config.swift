import AppKit
import Foundation
import os
import Yams

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/Config")

class ConfigParseAlert: NSAlert {
  init(error: Error) {
    super.init()
    self.messageText = "Unable to load configuration file"
    self.informativeText =
      "Unable to load configuration file: \(error.localizedDescription) The built-in defaults will be used instead."
    self.addButton(withTitle: "OK")
    self.alertStyle = .warning
  }
}

class HotKeyParseAlert: NSAlert {
  init(hotKey: String) {
    super.init()
    self.messageText = "Unable to register hot key"
    self.informativeText =
      "Unable to register hot key \(hotKey). Make sure it's correctly specified."
    self.addButton(withTitle: "OK")
    self.alertStyle = .warning
  }
}

class Config {
  struct HotKeyValues: Codable {
    var showCommandEntry: String = "option+command+t"
  }

  struct CommandConfigurationValues: Codable {
    var shell: String = "bash"
    var timeout: Double = 5
    var keep: Bool = false
    var animate: Bool = false
    var waitForExit: Bool = false
    var sourceBashProfile: Bool = true
    var delayAfterExit: Double = 3
    var workingDirectory: String? = nil
  }

  struct ConfigValues: Codable {
    var commandConfiguration = CommandConfigurationValues()
    var hotKeys = HotKeyValues()
  }

  private(set) static var main = ConfigValues()
  private(set) static var user: ConfigValues?
  public static var current: ConfigValues {
    self.user ?? self.main
  }

  public static var directory: URL {
    var path = FileManager.default.homeDirectoryForCurrentUser
    path.appendPathComponent(".config", isDirectory: true)
    path.appendPathComponent("quickterm", isDirectory: true)
    return path
  }

  public static var filePath: URL {
    var path = self.directory
    path.appendPathComponent("config.yml", isDirectory: false)
    return path
  }

  class func load() throws {
    // Load ~/.config/quickterm/config.yml
    let data = try Data(contentsOf: self.filePath, options: [])
    let decoder = YAMLDecoder()
    self.user = try decoder.decode(ConfigValues.self, from: data)
    logger.debug("Loaded user config values")
  }

  class func dump() throws {
    // Create ~/.config/quickterm if it does not exist
    try FileManager.default.createDirectory(
      atPath: self.directory.path,
      withIntermediateDirectories: true,
      attributes: nil
    )

    // Create ~/.config/quickterm/config.yml if it does not exist
    if !FileManager.default.fileExists(atPath: self.filePath.path) {
      let encoder = YAMLEncoder()
      let data = try encoder.encode(self.main)
      try data.write(to: self.filePath, atomically: false, encoding: .utf8)
    }
  }
}
