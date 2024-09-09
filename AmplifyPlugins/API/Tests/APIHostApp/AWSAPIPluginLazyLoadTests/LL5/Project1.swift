//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Project1: Model {
    public let projectId: String
    public let name: String
    var _team: LazyReference<Team1>
    public var team: Team1?   {
        get async throws {
            try await _team.get()
        }
    }
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    public var project1TeamTeamId: String?
    public var project1TeamName: String?

    public init(
        projectId: String,
        name: String,
        team: Team1? = nil,
        project1TeamTeamId: String? = nil,
        project1TeamName: String? = nil
    ) {
        self.init(
            projectId: projectId,
            name: name,
            team: team,
            createdAt: nil,
            updatedAt: nil,
            project1TeamTeamId: project1TeamTeamId,
            project1TeamName: project1TeamName
        )
    }
    init(
        projectId: String,
        name: String,
        team: Team1? = nil,
        createdAt: Temporal.DateTime? = nil,
        updatedAt: Temporal.DateTime? = nil,
        project1TeamTeamId: String? = nil,
        project1TeamName: String? = nil
    ) {
        self.projectId = projectId
        self.name = name
        self._team = LazyReference(team)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.project1TeamTeamId = project1TeamTeamId
        self.project1TeamName = project1TeamName
    }
    public mutating func setTeam(_ team: Team1? = nil) {
        _team = LazyReference(team)
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.projectId = try values.decode(String.self, forKey: .projectId)
        self.name = try values.decode(String.self, forKey: .name)
        self._team = try values.decodeIfPresent(LazyReference<Team1>.self, forKey: .team) ?? LazyReference(identifiers: nil)
        self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
        self.project1TeamTeamId = try? values.decode(String?.self, forKey: .project1TeamTeamId)
        self.project1TeamName = try? values.decode(String?.self, forKey: .project1TeamName)
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
