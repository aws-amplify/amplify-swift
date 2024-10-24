//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension ModelExplicitCustomPk {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case userId
    case name
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let modelExplicitCustomPk = ModelExplicitCustomPk.keys

    model.pluralName = "ModelExplicitCustomPks"

    model.attributes(
      .index(fields: ["userId"], name: nil),
      .primaryKey(fields: [modelExplicitCustomPk.userId])
    )

    model.fields(
      .field(modelExplicitCustomPk.userId, is: .required, ofType: .string),
      .field(modelExplicitCustomPk.name, is: .optional, ofType: .string),
      .field(modelExplicitCustomPk.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(modelExplicitCustomPk.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ModelExplicitCustomPk: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension ModelExplicitCustomPk.IdentifierProtocol {
  static func identifier(userId: String) -> Self {
    .make(fields: [(name: "userId", value: userId)])
  }
}
