// swiftlint:disable all
import Amplify
import Foundation

public struct Team2: Model {
  public let id: String
  public var name: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String) {
    self.init(id: id,
      name: name,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}