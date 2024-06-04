// swiftlint:disable all
import Amplify
import Foundation

public struct Todo5: Model {
  public let id: String
  public var content: String?
  public var completed: Bool?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String? = nil,
      completed: Bool? = nil) {
    self.init(id: id,
      content: content,
      completed: completed,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String? = nil,
      completed: Bool? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.completed = completed
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}