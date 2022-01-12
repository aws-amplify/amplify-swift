//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public class Project4bV2: Model {
  public let id: String
  public var name: String?
  public var team: Team4bV2?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var project4bV2TeamId: String?

    public convenience init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team4bV2? = nil,
      project4bV2TeamId: String? = nil) {
    self.init(id: id,
      name: name,
      team: team,
      createdAt: nil,
      updatedAt: nil,
      project4bV2TeamId: project4bV2TeamId)
  }
  internal init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team4bV2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      project4bV2TeamId: String? = nil) {
      self.id = id
      self.name = name
      self.team = team
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.project4bV2TeamId = project4bV2TeamId
  }
}
