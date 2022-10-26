// swiftlint:disable all
import Amplify
import Foundation

public struct Project2: Model {
    public let projectId: String
    public let name: String
    internal var _team: LazyModel<Team2>
    public var team: Team2? {
        get async throws {
            try await _team.get()
        }
    }
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
        self._team = LazyModel(element: team)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.project2TeamTeamId = project2TeamTeamId
        self.project2TeamName = project2TeamName
    }

    public mutating func setTeam(_ team: Team2?) {
        self._team = LazyModel(element: team)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try values.decode(String.self, forKey: .projectId)
        name = try values.decode(String.self, forKey: .name)
        do {
            _team = try values.decode(LazyModel<Team2>.self, forKey: .team)
        } catch {
            _team = LazyModel(identifiers: nil)
        }

        createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
        project2TeamTeamId = try values.decode(String?.self, forKey: .project2TeamTeamId)
        project2TeamName = try values.decode(String?.self, forKey: .project2TeamName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(name, forKey: .name)
        try container.encode(_team, forKey: .team)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(project2TeamTeamId, forKey: .project2TeamTeamId)
        try container.encode(project2TeamName, forKey: .project2TeamName)
    }
}
