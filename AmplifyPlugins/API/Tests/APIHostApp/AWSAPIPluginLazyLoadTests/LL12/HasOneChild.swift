// swiftlint:disable all
import Amplify
import Foundation

public struct HasOneChild: Model {
  public let id: String
  public var content: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String? = nil) {
    self.init(id: id,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      content = try values.decode(String?.self, forKey: .content)
      createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(content, forKey: .content)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}