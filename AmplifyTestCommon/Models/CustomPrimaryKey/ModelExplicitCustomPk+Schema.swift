//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension ModelExplicitCustomPk {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case userId
    case name
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let modelExplicitCustomPk = ModelExplicitCustomPk.keys

    model.pluralName = "ModelExplicitCustomPks"

    model.attributes(
      .index(fields: ["userId"], name: nil)
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

extension ModelExplicitCustomPk.IdentifierProtocol {
    public static func identifier(userId: String) -> Self {
        .make(fields: [(name: "userId", value: userId)])
    }
}
