// swiftlint:disable all
import Amplify
import Foundation

public struct Project1: Model {
  public let id: String
  public var name: String?
  public var team: Team1?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team1? = nil) {
    self.init(id: id,
      name: name,
      team: team,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team1? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.team = team
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}