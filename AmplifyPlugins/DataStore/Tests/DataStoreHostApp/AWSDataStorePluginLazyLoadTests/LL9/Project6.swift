//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Project6: Model {
    public let projectId: String
    public let name: String
    var _team: LazyReference<Team6>
    public var team: Team6? {
        get async throws {
            try await _team.get()
        }
    }
    public var teamId: String?
    public var teamName: String?
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?

    public init(
        projectId: String,
        name: String,
        team: Team6? = nil,
        teamId: String? = nil,
        teamName: String? = nil
    ) {
        self.init(
            projectId: projectId,
            name: name,
            team: team,
            teamId: teamId,
            teamName: teamName,
            createdAt: nil,
            updatedAt: nil
        )
    }
    init(
        projectId: String,
        name: String,
        team: Team6? = nil,
        teamId: String? = nil,
        teamName: String? = nil,
        createdAt: Temporal.DateTime? = nil,
        updatedAt: Temporal.DateTime? = nil
    ) {
        self.projectId = projectId
        self.name = name
        self._team = LazyReference(team)
        self.teamId = teamId
        self.teamName = teamName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public mutating func setTeam(_ team: Team6?) {
        _team = LazyReference(team)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.projectId = try values.decode(String.self, forKey: .projectId)
        self.name = try values.decode(String.self, forKey: .name)
        self._team = try values.decodeIfPresent(LazyReference<Team6>.self, forKey: .team) ?? LazyReference(identifiers: nil)
        self.teamId = try values.decode(String?.self, forKey: .teamId)
        self.teamName = try values.decode(String?.self, forKey: .teamName)
        self.createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        self.updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(name, forKey: .name)
        try container.encode(_team, forKey: .team)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(teamName, forKey: .teamName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
