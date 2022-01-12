//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Team2V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let team2V2 = Team2V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Team2V2s"

    model.fields(
      .id(),
      .field(team2V2.name, is: .required, ofType: .string),
      .field(team2V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team2V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
