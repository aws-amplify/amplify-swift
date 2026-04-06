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
    case teamId
    case name
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let team2 = Team2.keys

    model.pluralName = "Team2s"

    model.attributes(
      .index(fields: ["teamId", "name"], name: nil),
      .primaryKey(fields: [team2.teamId, team2.name])
    )

    model.fields(
      .field(team2.teamId, is: .required, ofType: .string),
      .field(team2.name, is: .required, ofType: .string),
      .field(team2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Team2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Team2.IdentifierProtocol {
  static func identifier(
    teamId: String,
    name: String
  ) -> Self {
    .make(fields: [(name: "teamId", value: teamId), (name: "name", value: name)])
  }
}
