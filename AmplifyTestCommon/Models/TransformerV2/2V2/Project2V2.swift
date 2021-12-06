//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Project2V2: Model {
  public let id: String
  public var name: String?
  public var teamID: String
  public var team: Team2V2?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      name: String? = nil,
      teamID: String,
      team: Team2V2? = nil) {
    self.init(id: id,
      name: name,
      teamID: teamID,
      team: team,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String? = nil,
      teamID: String,
      team: Team2V2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.teamID = teamID
      self.team = team
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
