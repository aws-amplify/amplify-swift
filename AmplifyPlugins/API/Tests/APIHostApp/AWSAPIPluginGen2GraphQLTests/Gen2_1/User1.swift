// swiftlint:disable all
import Amplify
import Foundation

public struct User1: Model {
  public let id: String
  public var lastKnownLocation: Location1?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      lastKnownLocation: Location1? = nil) {
    self.init(id: id,
      lastKnownLocation: lastKnownLocation,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      lastKnownLocation: Location1? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.lastKnownLocation = lastKnownLocation
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}