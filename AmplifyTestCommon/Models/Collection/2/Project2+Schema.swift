//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Project2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case teamID
    case team
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
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
