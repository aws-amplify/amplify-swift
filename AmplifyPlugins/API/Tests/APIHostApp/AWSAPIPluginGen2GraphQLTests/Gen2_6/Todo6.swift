// swiftlint:disable all
import Amplify
import Foundation

public struct Todo6: Model {
  public let todoId: String
  public var content: String?
  public var completed: Bool?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(todoId: String,
      content: String? = nil,
      completed: Bool? = nil) {
    self.init(todoId: todoId,
      content: content,
      completed: completed,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(todoId: String,
      content: String? = nil,
      completed: Bool? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.todoId = todoId
      self.content = content
      self.completed = completed
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}