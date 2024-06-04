// swiftlint:disable all
import Amplify
import Foundation

public struct Post1: Model {
  public let id: String
  public var location: Location1?
  public var content: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      location: Location1? = nil,
      content: String? = nil) {
    self.init(id: id,
      location: location,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      location: Location1? = nil,
      content: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.location = location
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}