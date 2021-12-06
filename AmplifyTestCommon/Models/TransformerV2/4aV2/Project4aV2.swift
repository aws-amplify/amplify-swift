//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

// This was manually modified to compile - currently codegen will generate `structs`
// which will fail with error:
// <>

public class Project4aV2: Model {
  public let id: String
  public var name: String?
  public var team: Team4aV2?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var project4aV2TeamId: String?

    public convenience init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team4aV2? = nil,
      project4aV2TeamId: String? = nil) {
    self.init(id: id,
      name: name,
      team: team,
      createdAt: nil,
      updatedAt: nil,
      project4aV2TeamId: project4aV2TeamId)
  }
  internal init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team4aV2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      project4aV2TeamId: String? = nil) {
      self.id = id
      self.name = name
      self.team = team
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.project4aV2TeamId = project4aV2TeamId
  }
}
