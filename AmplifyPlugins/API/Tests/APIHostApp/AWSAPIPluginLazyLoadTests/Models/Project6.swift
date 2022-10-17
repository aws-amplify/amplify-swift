// swiftlint:disable all
import Amplify
import Foundation

public struct Project6: Model {
  public let projectId: String
  public let name: String
  public var team: Team6?
  public var teamId: String?
  public var teamName: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(projectId: String,
      name: String,
      team: Team6? = nil,
      teamId: String? = nil,
      teamName: String? = nil) {
    self.init(projectId: projectId,
      name: name,
      team: team,
      teamId: teamId,
      teamName: teamName,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(projectId: String,
      name: String,
      team: Team6? = nil,
      teamId: String? = nil,
      teamName: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.projectId = projectId
      self.name = name
      self.team = team
      self.teamId = teamId
      self.teamName = teamName
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}