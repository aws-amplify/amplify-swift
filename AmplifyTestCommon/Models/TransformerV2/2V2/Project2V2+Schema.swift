//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Project2V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case teamID
    case team
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let project2V2 = Project2V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Project2V2s"

    model.fields(
      .id(),
      .field(project2V2.name, is: .optional, ofType: .string),
      .field(project2V2.teamID, is: .required, ofType: .string),
      .hasOne(project2V2.team, is: .optional, ofType: Team2V2.self, associatedWith: Team2V2.keys.id, targetName: "teamID"),
      .field(project2V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project2V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
