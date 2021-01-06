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
  public let id: String
  public var name: String?
  public var teamID: String
  public var team: Team2?

  public init(id: String = UUID().uuidString,
      name: String? = nil,
      teamID: String,
      team: Team2? = nil) {
      self.id = id
      self.name = name
      self.teamID = teamID
      self.team = team
  }
}
