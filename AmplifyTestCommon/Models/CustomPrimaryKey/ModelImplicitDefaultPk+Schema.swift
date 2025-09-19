//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension ModelImplicitDefaultPk {
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
    let modelImplicitDefaultPk = ModelImplicitDefaultPk.keys

    model.pluralName = "ModelImplicitDefaultPks"

    model.fields(
      .id(),
      .field(modelImplicitDefaultPk.name, is: .optional, ofType: .string),
      .field(modelImplicitDefaultPk.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(modelImplicitDefaultPk.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ModelImplicitDefaultPk: ModelIdentifiable {
    public typealias IdentifierFormat = ModelIdentifierFormat.Default
    public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
