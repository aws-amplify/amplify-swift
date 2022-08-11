//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoCustomOwnerImplicit {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let todoCustomOwnerImplicit = TodoCustomOwnerImplicit.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "dominus", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "TodoCustomOwnerImplicits"

    model.fields(
      .id(),
      .field(todoCustomOwnerImplicit.title, is: .required, ofType: .string),
      .field(todoCustomOwnerImplicit.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoCustomOwnerImplicit.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
