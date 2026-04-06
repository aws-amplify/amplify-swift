//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension ModelExplicitDefaultPk {
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
    let modelExplicitDefaultPk = ModelExplicitDefaultPk.keys

    model.pluralName = "ModelExplicitDefaultPks"

    model.attributes(
      .index(fields: ["id"], name: nil)
    )

    model.fields(
      .id(),
      .field(modelExplicitDefaultPk.name, is: .optional, ofType: .string),
      .field(modelExplicitDefaultPk.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(modelExplicitDefaultPk.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ModelExplicitDefaultPk: ModelIdentifiable {
    public typealias IdentifierFormat = ModelIdentifierFormat.Custom
    public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension ModelExplicitDefaultPk.IdentifierProtocol {
    static func identifier(id: String) -> Self {
        .make(fields: [(name: "id", value: id)])
    }
}
