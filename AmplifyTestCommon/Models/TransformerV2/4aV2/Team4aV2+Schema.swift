//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Team4aV2 {
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
    let team4aV2 = Team4aV2.keys

    model.pluralName = "Team4aV2s"

    model.fields(
      .id(),
      .field(team4aV2.name, is: .required, ofType: .string),
      .belongsTo(team4aV2.project, is: .optional, ofType: Project4aV2.self, targetName: "team4aV2ProjectId"),
      .field(team4aV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team4aV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
