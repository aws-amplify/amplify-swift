//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension TodoImplicitOwnerField {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let todoImplicitOwnerField = TodoImplicitOwnerField.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "TodoImplicitOwnerFields"
    model.syncPluralName = "TodoImplicitOwnerFields"

    model.attributes(
      .primaryKey(fields: [todoImplicitOwnerField.id])
    )

    model.fields(
      .field(todoImplicitOwnerField.id, is: .required, ofType: .string),
      .field(todoImplicitOwnerField.content, is: .required, ofType: .string),
      .field(todoImplicitOwnerField.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoImplicitOwnerField.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension TodoImplicitOwnerField: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
