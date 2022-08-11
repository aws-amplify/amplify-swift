//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension OwnerPublicOIDAPIPost {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let ownerPublicOIDAPIPost = OwnerPublicOIDAPIPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "sub", provider: .oidc, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OwnerPublicOIDAPIPosts"
    model.syncPluralName = "OwnerPublicOIDAPIPosts"

    model.fields(
      .id(),
      .field(ownerPublicOIDAPIPost.name, is: .required, ofType: .string),
      .field(ownerPublicOIDAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ownerPublicOIDAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
