public protocol CommandErrorProtocol: Error {
  var title: String? { get }
  var description: String? { get }
}

public struct CommandError: CommandErrorProtocol {
  public var title: String?
  public var description: String?

  public init(title: String?, description: String?) {
    self.title = title ?? "Error"
    self.description = description ?? ""
  }
}
