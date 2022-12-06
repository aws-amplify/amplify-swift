// swiftlint:disable all
import Amplify
import Foundation

public struct StrangeExplicitChild: Model {
  public let strangeId: String
  public let content: String
  internal var _parent: LazyReference<CompositePKParent>
  public var parent: CompositePKParent   {
      get async throws { 
        try await _parent.require()
      } 
    }
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
      self._parent = LazyReference(parent)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setParent(parent: CompositePKParent) {
    self._parent = LazyReference(parent)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      strangeId = try values.decode(String.self, forKey: .strangeId)
      content = try values.decode(String.self, forKey: .content)
      _parent = try values.decodeIfPresent(LazyReference<CompositePKParent>.self, forKey: .parent) ?? LazyReference(identifiers: nil)
      createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(strangeId, forKey: .strangeId)
      try container.encode(content, forKey: .content)
      try container.encode(_parent, forKey: .parent)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}