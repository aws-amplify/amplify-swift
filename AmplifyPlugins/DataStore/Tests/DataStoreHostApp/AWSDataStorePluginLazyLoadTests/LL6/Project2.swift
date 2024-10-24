//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Project2: Model {
    public let projectId: String
    public let name: String
    var _team: LazyReference<Team2>
    public var team: Team2? {
        get async throws {
            try await _team.get()
        }
    }
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    public var project2TeamTeamId: String?
    public var project2TeamName: String?

    public init(
        projectId: String,
        name: String,
        team: Team2? = nil,
        project2TeamTeamId: String? = nil,
        project2TeamName: String? = nil
    ) {
        self.init(
            projectId: projectId,
            name: name,
            team: team,
            createdAt: nil,
            updatedAt: nil,
            project2TeamTeamId: project2TeamTeamId,
            project2TeamName: project2TeamName
        )
    }
    init(
        projectId: String,
        name: String,
        team: Team2? = nil,
        createdAt: Temporal.DateTime? = nil,
        updatedAt: Temporal.DateTime? = nil,
        project2TeamTeamId: String? = nil,
        project2TeamName: String? = nil
    ) {
        self.projectId = projectId
        self.name = name
        self._team = LazyReference(team)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.project2TeamTeamId = project2TeamTeamId
        self.project2TeamName = project2TeamName
    }

    public mutating func setTeam(_ team: Team2?) {
        _team = LazyReference(team)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.projectId = try values.decode(String.self, forKey: .projectId)
        self.name = try values.decode(String.self, forKey: .name)
        self._team = try values.decodeIfPresent(LazyReference<Team2>.self, forKey: .team) ?? LazyReference(identifiers: nil)
        self.createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        self.updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
        self.project2TeamTeamId = try values.decode(String?.self, forKey: .project2TeamTeamId)
        self.project2TeamName = try values.decode(String?.self, forKey: .project2TeamName)
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
