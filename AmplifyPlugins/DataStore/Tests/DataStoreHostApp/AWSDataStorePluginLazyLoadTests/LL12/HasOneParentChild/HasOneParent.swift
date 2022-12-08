// swiftlint:disable all
import Amplify
import Foundation

public struct HasOneParent: Model {
  public let id: String
  internal var _child: LazyReference<HasOneChild>
  public var child: HasOneChild?   {
      get async throws { 
        try await _child.get()
      } 
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var hasOneParentChildId: String?
  
  public init(id: String = UUID().uuidString,
      child: HasOneChild? = nil,
      hasOneParentChildId: String? = nil) {
    self.init(id: id,
      child: child,
      createdAt: nil,
      updatedAt: nil,
      hasOneParentChildId: hasOneParentChildId)
  }
  internal init(id: String = UUID().uuidString,
      child: HasOneChild? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      hasOneParentChildId: String? = nil) {
      self.id = id
      self._child = LazyReference(child)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.hasOneParentChildId = hasOneParentChildId
  }
  public mutating func setChild(child: HasOneChild? = nil) {
    self._child = LazyReference(child)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _child = try values.decodeIfPresent(LazyReference<HasOneChild>.self, forKey: .child) ?? LazyReference(identifiers: nil)
      createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
      hasOneParentChildId = try values.decode(String?.self, forKey: .hasOneParentChildId)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_child, forKey: .child)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
      try container.encode(hasOneParentChildId, forKey: .hasOneParentChildId)
  }
}