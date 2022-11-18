// swiftlint:disable all
import Amplify
import Foundation

public struct Team1: Model {
    public let teamId: String
    public let name: String
    internal var _project: LazyReference<Project1>
    public var project: Project1? {
        get async throws {
            try await _project.get()
        }
    }
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    
    public init(teamId: String,
                name: String,
                project: Project1? = nil) {
        self.init(teamId: teamId,
                  name: name,
                  project: project,
                  createdAt: nil,
                  updatedAt: nil)
    }
    internal init(teamId: String,
                  name: String,
                  project: Project1? = nil,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.teamId = teamId
        self.name = name
        self._project = LazyReference(project)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public mutating func setProject(_ project: Project1?) {
        self._project = LazyReference(project)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        teamId = try values.decode(String.self, forKey: .teamId)
        name = try values.decode(String.self, forKey: .name)
        do {
            _project = try values.decode(LazyReference<Project1>.self, forKey: .project)
        } catch {
            _project = LazyReference(identifiers: nil)
        }
        createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(name, forKey: .name)
        try container.encode(_project, forKey: .project)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
