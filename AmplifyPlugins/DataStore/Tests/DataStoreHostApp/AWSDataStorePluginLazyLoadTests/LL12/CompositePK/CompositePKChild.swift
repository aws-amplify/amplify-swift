// swiftlint:disable all
import Amplify
import Foundation

public struct CompositePKChild: Model {
  public let childId: String
  public let content: String
  internal var _parent: LazyReference<CompositePKParent>
  public var parent: CompositePKParent?   {
      get async throws { 
        try await _parent.get()
      } 
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(childId: String,
      content: String,
      parent: CompositePKParent? = nil) {
    self.init(childId: childId,
      content: content,
      parent: parent,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(childId: String,
      content: String,
      parent: CompositePKParent? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.childId = childId
      self.content = content
      self._parent = LazyReference(parent)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setParent(_ parent: CompositePKParent? = nil) {
    self._parent = LazyReference(parent)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      childId = try values.decode(String.self, forKey: .childId)
      content = try values.decode(String.self, forKey: .content)
      _parent = try values.decodeIfPresent(LazyReference<CompositePKParent>.self, forKey: .parent) ?? LazyReference(identifiers: nil)
      createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(childId, forKey: .childId)
      try container.encode(content, forKey: .content)
      try container.encode(_parent, forKey: .parent)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
