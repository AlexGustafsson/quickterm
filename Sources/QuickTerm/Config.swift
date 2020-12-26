import Foundation
import Yams

class Config {
  struct HotKeyValues: Codable {
    var showCommandEntry: String = "option+cmd+t"
  }

  struct CommandConfigurationValues: Codable {
    var shell: String = "bash"
    var timeout: Double = 5
    var keep: Bool = false
    var animate: Bool = false
    var waitForExit: Bool = false
    var sourceBashProfile: Bool = true
    var delayAfterExit: Double = 3
  }

  struct ConfigValues: Codable {
    var commandConfiguration = CommandConfigurationValues()
    var hotkeys = HotKeyValues()
  }

  private(set) static var main = ConfigValues()
  private(set) static var user: ConfigValues?
  public static var current: ConfigValues {
    self.user ?? self.main
  }

  class func load() throws {
    // Load ~/.config/quickterm/config.yml
    var configFile = FileManager.default.homeDirectoryForCurrentUser
    configFile.appendPathComponent(".config", isDirectory: true)
    configFile.appendPathComponent("quickterm", isDirectory: true)
    configFile.appendPathComponent("config.yml", isDirectory: false)

    let data = try Data(contentsOf: configFile, options: [])
    let decoder = YAMLDecoder()
    self.user = try decoder.decode(ConfigValues.self, from: data)
    logger.debug("Loaded user config values")
  }

  class func dump() throws {
    // Create ~/.config/quickterm if it does not exist
    var configDirectory = FileManager.default.homeDirectoryForCurrentUser
    configDirectory.appendPathComponent(".config", isDirectory: true)
    configDirectory.appendPathComponent("quickterm", isDirectory: true)
    try FileManager.default.createDirectory(
      atPath: configDirectory.path,
      withIntermediateDirectories: true,
      attributes: nil
    )

    // Create ~/.config/quickterm/config.yml if it does not exist
    var configFile = configDirectory
    configFile.appendPathComponent("config.yml")
    if !FileManager.default.fileExists(atPath: configFile.path) {
      let encoder = YAMLEncoder()
      let data = try encoder.encode(self.main)
      try data.write(to: configFile, atomically: false, encoding: .utf8)
    }
  }
}
