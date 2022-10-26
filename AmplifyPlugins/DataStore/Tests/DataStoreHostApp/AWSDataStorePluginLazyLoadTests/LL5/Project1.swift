// swiftlint:disable all
import Amplify
import Foundation

public struct Project1: Model {
    public let projectId: String
    public let name: String
    internal var _team: LazyModel<Team1>
    public var team: Team1? {
        get async throws {
            try await _team.get()
        }
    }
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    public var project1TeamTeamId: String?
    public var project1TeamName: String?
    
    public init(projectId: String,
                name: String,
                team: Team1? = nil,
                project1TeamTeamId: String? = nil,
                project1TeamName: String? = nil) {
        self.init(projectId: projectId,
                  name: name,
                  team: team,
                  createdAt: nil,
                  updatedAt: nil,
                  project1TeamTeamId: project1TeamTeamId,
                  project1TeamName: project1TeamName)
    }
    internal init(projectId: String,
                  name: String,
                  team: Team1? = nil,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil,
                  project1TeamTeamId: String? = nil,
                  project1TeamName: String? = nil) {
        self.projectId = projectId
        self.name = name
        self._team = LazyModel(element: team)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.project1TeamTeamId = project1TeamTeamId
        self.project1TeamName = project1TeamName
    }
    
    public mutating func setTeam(_ team: Team1?) {
        self._team = LazyModel(element: team)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try values.decode(String.self, forKey: .projectId)
        name = try values.decode(String.self, forKey: .name)
        do {
            _team = try values.decode(LazyModel<Team1>.self, forKey: .team)
        } catch {
            _team = LazyModel(identifiers: nil)
        }
        createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
        project1TeamTeamId = try values.decode(String?.self, forKey: .project1TeamTeamId)
        project1TeamName = try values.decode(String?.self, forKey: .project1TeamName)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(name, forKey: .name)
        try container.encode(_team, forKey: .team)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(project1TeamTeamId, forKey: .project1TeamTeamId)
        try container.encode(project1TeamName, forKey: .project1TeamName)
    }
}
