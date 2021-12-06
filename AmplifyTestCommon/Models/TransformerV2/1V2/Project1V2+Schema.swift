//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Project1V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case team
    case createdAt
    case updatedAt
    case project1V2TeamId
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let project1V2 = Project1V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Project1V2s"

    model.fields(
      .id(),
      .field(project1V2.name, is: .optional, ofType: .string),
      .hasOne(project1V2.team, is: .optional, ofType: Team1V2.self, associatedWith: Team1V2.keys.id, targetName: "project1V2TeamId"),
      .field(project1V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project1V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project1V2.project1V2TeamId, is: .optional, ofType: .string)
    )
    }
}
