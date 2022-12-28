// swiftlint:disable all
import Amplify
import Foundation

public struct ChildSansBelongsTo: Model {
  public let childId: String
  public let content: String
  public var compositePKParentChildrenSansBelongsToCustomId: String
  public var compositePKParentChildrenSansBelongsToContent: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(childId: String,
      content: String,
      compositePKParentChildrenSansBelongsToCustomId: String,
      compositePKParentChildrenSansBelongsToContent: String? = nil) {
    self.init(childId: childId,
      content: content,
      compositePKParentChildrenSansBelongsToCustomId: compositePKParentChildrenSansBelongsToCustomId,
      compositePKParentChildrenSansBelongsToContent: compositePKParentChildrenSansBelongsToContent,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(childId: String,
      content: String,
      compositePKParentChildrenSansBelongsToCustomId: String,
      compositePKParentChildrenSansBelongsToContent: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.childId = childId
      self.content = content
      self.compositePKParentChildrenSansBelongsToCustomId = compositePKParentChildrenSansBelongsToCustomId
      self.compositePKParentChildrenSansBelongsToContent = compositePKParentChildrenSansBelongsToContent
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
