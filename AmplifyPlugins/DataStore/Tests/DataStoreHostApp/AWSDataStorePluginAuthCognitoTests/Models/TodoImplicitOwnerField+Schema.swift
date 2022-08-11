//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoImplicitOwnerField {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let todoImplicitOwnerField = TodoImplicitOwnerField.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "TodoImplicitOwnerFields"

    model.fields(
      .id(),
      .field(todoImplicitOwnerField.content, is: .required, ofType: .string),
      .field(todoImplicitOwnerField.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoImplicitOwnerField.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
