// swiftlint:disable all
import Amplify
import Foundation

public struct ModelCompositeMultiplePk: Model {
  public let id: String
  public let location: String
  public let name: String
  public var lastName: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      location: String,
      name: String,
      lastName: String? = nil) {
    self.init(id: id,
      location: location,
      name: name,
      lastName: lastName,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      location: String,
      name: String,
      lastName: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.location = location
      self.name = name
      self.lastName = lastName
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}