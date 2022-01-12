//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Project4aV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case team
    case createdAt
    case updatedAt
    case project4aV2TeamId
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let project4aV2 = Project4aV2.keys

    model.pluralName = "Project4aV2s"

    model.fields(
      .id(),
      .field(project4aV2.name, is: .optional, ofType: .string),
      .hasOne(project4aV2.team, is: .optional, ofType: Team4aV2.self, associatedWith: Team4aV2.keys.project, targetName: "project4aV2TeamId"),
      .field(project4aV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project4aV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project4aV2.project4aV2TeamId, is: .optional, ofType: .string)
    )
    }
}
