// swiftlint:disable all
import Amplify
import Foundation

public struct ImplicitChild: Model {
  public let childId: String
  public let content: String
  public var parent: CompositePKParent
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(childId: String,
      content: String,
      parent: CompositePKParent) {
    self.init(childId: childId,
      content: content,
      parent: parent,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(childId: String,
      content: String,
      parent: CompositePKParent,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.childId = childId
      self.content = content
      self.parent = parent
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}