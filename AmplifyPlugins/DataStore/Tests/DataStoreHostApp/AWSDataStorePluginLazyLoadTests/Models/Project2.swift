// swiftlint:disable all
import Amplify
import Foundation

public struct Project2: Model {
  public let projectId: String
  public let name: String
  public var team: Team2?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var project2TeamTeamId: String?
  public var project2TeamName: String?
  
  public init(projectId: String,
      name: String,
      team: Team2? = nil,
      project2TeamTeamId: String? = nil,
      project2TeamName: String? = nil) {
    self.init(projectId: projectId,
      name: name,
      team: team,
      createdAt: nil,
      updatedAt: nil,
      project2TeamTeamId: project2TeamTeamId,
      project2TeamName: project2TeamName)
  }
  internal init(projectId: String,
      name: String,
      team: Team2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      project2TeamTeamId: String? = nil,
      project2TeamName: String? = nil) {
      self.projectId = projectId
      self.name = name
      self.team = team
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.project2TeamTeamId = project2TeamTeamId
      self.project2TeamName = project2TeamName
  }
}