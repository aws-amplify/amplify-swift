//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Team5: Model {
  public let teamId: String
  public let name: String
  var _project: LazyReference<Project5>
  public var project: Project5?   {
      get async throws {
        try await _project.get()
      }
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    teamId: String,
    name: String,
    project: Project5? = nil
  ) {
    self.init(
      teamId: teamId,
      name: name,
      project: project,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    teamId: String,
    name: String,
    project: Project5? = nil,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.teamId = teamId
      self.name = name
      self._project = LazyReference(project)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setProject(_ project: Project5? = nil) {
    _project = LazyReference(project)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.teamId = try values.decode(String.self, forKey: .teamId)
      self.name = try values.decode(String.self, forKey: .name)
      self._project = try values.decodeIfPresent(LazyReference<Project5>.self, forKey: .project) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
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
