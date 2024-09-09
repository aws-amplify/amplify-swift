//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Team2 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let team2 = Team2.keys

    model.pluralName = "Team2s"

    model.fields(
      .id(),
      .field(team2.name, is: .required, ofType: .string),
      .field(team2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
