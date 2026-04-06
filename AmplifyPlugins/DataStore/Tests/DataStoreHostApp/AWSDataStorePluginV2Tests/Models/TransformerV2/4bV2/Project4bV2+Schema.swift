//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Project4bV2 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case team
    case createdAt
    case updatedAt
    case project4bV2TeamId
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let project4bV2 = Project4bV2.keys

    model.pluralName = "Project4bV2s"

    model.fields(
      .id(),
      .field(project4bV2.name, is: .optional, ofType: .string),
      .hasOne(project4bV2.team, is: .optional, ofType: Team4bV2.self, associatedWith: Team4bV2.keys.project, targetName: "project4bV2TeamId"),
      .field(project4bV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project4bV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project4bV2.project4bV2TeamId, is: .optional, ofType: .string)
    )
    }
}
