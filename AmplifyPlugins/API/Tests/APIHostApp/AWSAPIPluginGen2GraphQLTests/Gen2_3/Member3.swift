// swiftlint:disable all
import Amplify
import Foundation

public struct Member3: Model {
  public let id: String
  public var name: String
  internal var _team: LazyReference<Team3>
  public var team: Team3?   {
      get async throws { 
        try await _team.get()
      } 
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      team: Team3? = nil) {
    self.init(id: id,
      name: name,
      team: team,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      team: Team3? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self._team = LazyReference(team)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setTeam(_ team: Team3? = nil) {
    self._team = LazyReference(team)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      name = try values.decode(String.self, forKey: .name)
      _team = try values.decodeIfPresent(LazyReference<Team3>.self, forKey: .team) ?? LazyReference(identifiers: nil)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(name, forKey: .name)
      try container.encode(_team, forKey: .team)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}