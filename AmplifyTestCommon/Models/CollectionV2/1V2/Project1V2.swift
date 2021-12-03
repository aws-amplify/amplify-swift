//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Project1V2: Model {
  public let id: String
  public var name: String?
  public var team: Team1V2?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var project1V2TeamId: String?

  public init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team1V2? = nil,
      project1V2TeamId: String? = nil) {
    self.init(id: id,
      name: name,
      team: team,
      createdAt: nil,
      updatedAt: nil,
      project1V2TeamId: project1V2TeamId)
  }
  internal init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team1V2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      project1V2TeamId: String? = nil) {
      self.id = id
      self.name = name
      self.team = team
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.project1V2TeamId = project1V2TeamId
  }
}
