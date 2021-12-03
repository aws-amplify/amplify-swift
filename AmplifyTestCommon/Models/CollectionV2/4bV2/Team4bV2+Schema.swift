//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Team4bV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case project
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let team4bV2 = Team4bV2.keys

    model.pluralName = "Team4bV2s"

    model.fields(
      .id(),
      .field(team4bV2.name, is: .required, ofType: .string),
      .belongsTo(team4bV2.project, is: .optional, ofType: Project4bV2.self, targetName: "projectID"),
      .field(team4bV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team4bV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
