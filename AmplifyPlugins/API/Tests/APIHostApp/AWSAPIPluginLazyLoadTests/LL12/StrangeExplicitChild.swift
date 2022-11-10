// swiftlint:disable all
import Amplify
import Foundation

public struct StrangeExplicitChild: Model {
  public let strangeId: String
  public let content: String
  public var parent: CompositePKParent
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(strangeId: String,
      content: String,
      parent: CompositePKParent) {
    self.init(strangeId: strangeId,
      content: content,
      parent: parent,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(strangeId: String,
      content: String,
      parent: CompositePKParent,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.strangeId = strangeId
      self.content = content
      self.parent = parent
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}