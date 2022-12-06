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
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      customId = try values.decode(String.self, forKey: .customId)
      content = try values.decode(String.self, forKey: .content)
      children = try values.decode(List<CompositePKChild>?.self, forKey: .children)
      implicitChildren = try values.decode(List<ImplicitChild>?.self, forKey: .implicitChildren)
      strangeChildren = try values.decode(List<StrangeExplicitChild>?.self, forKey: .strangeChildren)
      childrenSansBelongsTo = try values.decode(List<ChildSansBelongsTo>?.self, forKey: .childrenSansBelongsTo)
      createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(customId, forKey: .customId)
      try container.encode(content, forKey: .content)
      try container.encode(children, forKey: .children)
      try container.encode(implicitChildren, forKey: .implicitChildren)
      try container.encode(strangeChildren, forKey: .strangeChildren)
      try container.encode(childrenSansBelongsTo, forKey: .childrenSansBelongsTo)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}