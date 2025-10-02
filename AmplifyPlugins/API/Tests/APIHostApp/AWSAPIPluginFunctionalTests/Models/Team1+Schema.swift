//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Team1 {
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
    let team1 = Team1.keys

    model.pluralName = "Team1s"

    model.fields(
      .id(),
      .field(team1.name, is: .required, ofType: .string),
      .field(team1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
