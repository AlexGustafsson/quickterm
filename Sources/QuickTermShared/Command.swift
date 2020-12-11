import Foundation

@objc(Command) public class Command: NSObject, NSSecureCoding {
	public static var supportsSecureCoding: Bool { return true }

	public let workingDirectory: URL!
	public let command: String!

	public func encode(with encoder: NSCoder){
		encoder.encode(self.workingDirectory as NSURL, forKey: "workingDirectory")
		encoder.encode(self.command as NSString, forKey: "command")
	}

	public required init?(coder decoder: NSCoder) {
		guard
			let workingDirectory = decoder.decodeObject(of: NSURL.self, forKey: "workingDirectory") as URL?,
			let command = decoder.decodeObject(of: NSString.self, forKey: "command") as String?
		else {
      return nil
    }

		self.workingDirectory = workingDirectory
		self.command = command
	}

	public init(workingDirectory: URL, command: String) {
		self.workingDirectory = workingDirectory
		self.command = command
	}
}
