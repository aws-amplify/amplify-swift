// swiftlint:disable all
import Amplify
import Foundation

public struct CompositePKParent: Model {
  public let customId: String
  public let content: String
  public var children: List<CompositePKChild>?
  public var implicitChildren: List<ImplicitChild>?
  public var strangeChildren: List<StrangeExplicitChild>?
  public var childrenSansBelongsTo: List<ChildSansBelongsTo>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(customId: String,
      content: String,
      children: List<CompositePKChild>? = [],
      implicitChildren: List<ImplicitChild>? = [],
      strangeChildren: List<StrangeExplicitChild>? = [],
      childrenSansBelongsTo: List<ChildSansBelongsTo>? = []) {
    self.init(customId: customId,
      content: content,
      children: children,
      implicitChildren: implicitChildren,
      strangeChildren: strangeChildren,
      childrenSansBelongsTo: childrenSansBelongsTo,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(customId: String,
      content: String,
      children: List<CompositePKChild>? = [],
      implicitChildren: List<ImplicitChild>? = [],
      strangeChildren: List<StrangeExplicitChild>? = [],
      childrenSansBelongsTo: List<ChildSansBelongsTo>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.customId = customId
      self.content = content
      self.children = children
      self.implicitChildren = implicitChildren
      self.strangeChildren = strangeChildren
      self.childrenSansBelongsTo = childrenSansBelongsTo
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
