import Foundation

@objc public class CommandConfiguration: NSObject, NSSecureCoding, Codable {
	public static var supportsSecureCoding: Bool { return true }

	// The directory to execute the command in.
	public let workingDirectory: URL!
	// The command itself including arguments.
	public let command: String!
	// The shell to use, such as bash.
	// Must be available by using /usr/bin/env shell.
	public let shell: String
	// Number of seconds to allow a command to run before timing out.
	// Use -1 to never time out.
	public let timeout: Double
	// Whether or not to keep the command visible after it has been completed
	// or timed out.
	public let keep: Bool
	// The time to start the command. If nil, it will be started as soon as possible.
	public let startTime: Date
	// Whether or not to animate the output.
	public let animate: Bool
	// Whether or not to wait for the command to exit before presenting the view
	public let waitForExit: Bool

	public func encode(with encoder: NSCoder){
		encoder.encode(self.workingDirectory as NSURL, forKey: "workingDirectory")
		encoder.encode(self.command as NSString, forKey: "command")
		encoder.encode(self.shell as NSString, forKey: "shell")
		encoder.encode(self.timeout, forKey: "timeout")
		encoder.encode(self.keep, forKey: "keep")
		encoder.encode(self.startTime as NSDate, forKey: "startTime")
		encoder.encode(self.animate, forKey: "animate")
		encoder.encode(self.waitForExit, forKey: "waitForExit")
	}

	public required init?(coder decoder: NSCoder) {
		guard
			let workingDirectory = decoder.decodeObject(of: NSURL.self, forKey: "workingDirectory") as URL?,
			let command = decoder.decodeObject(of: NSString.self, forKey: "command") as String?,
			let shell = decoder.decodeObject(of: NSString.self, forKey: "shell") as String?,
			let timeout = decoder.decodeDouble(forKey: "timeout") as Double?,
			let keep = decoder.decodeBool(forKey: "keep") as Bool?,
			let startTime = decoder.decodeObject(of: NSDate.self, forKey: "startTime") as Date?,
			let animate = decoder.decodeBool(forKey: "animate") as Bool?,
			let waitForExit = decoder.decodeBool(forKey: "waitForExit") as Bool?
		else {
      return nil
    }

		self.workingDirectory = workingDirectory
		self.command = command
		self.shell = shell
		self.timeout = timeout
		self.keep = keep
		self.startTime = startTime
		self.animate = animate
		self.waitForExit = waitForExit
	}

	public init(
			workingDirectory: URL,
			command: String,
			shell: String = "bash",
			timeout: Double = 5,
			keep: Bool = false,
			startTime: Date? = nil,
			animate: Bool = false,
			waitForExit: Bool = false
	) {
		self.workingDirectory = workingDirectory
		self.command = command
		self.shell = shell
		self.timeout = timeout
		self.keep = keep
		self.startTime = startTime ?? Date()
		self.animate = animate
		self.waitForExit = waitForExit
	}

	public func dump(pretty: Bool = false) throws -> String {
		let encoder = JSONEncoder()
		if pretty {
			encoder.outputFormatting = .prettyPrinted
		}

		let data = try encoder.encode(self)
		return String(data: data, encoding: .utf8)!
	}
}
