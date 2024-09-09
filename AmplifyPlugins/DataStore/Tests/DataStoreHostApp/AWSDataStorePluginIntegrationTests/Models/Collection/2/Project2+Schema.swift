//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Project2 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case teamID
    case team
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let project2 = Project2.keys

    model.listPluralName = "Project2s"
    model.syncPluralName = "Project2s"

    model.fields(
      .id(),
      .field(project2.name, is: .optional, ofType: .string),
      .field(project2.teamID, is: .required, ofType: .string),
      .hasOne(project2.team, is: .optional, ofType: Team2.self, associatedWith: Team2.keys.id, targetName: "teamID")
    )
    }
}
