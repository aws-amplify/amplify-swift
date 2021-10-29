//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension OwnerOIDCPost {
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
    let ownerOIDCPost = OwnerOIDCPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "sub", provider: .oidc, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OwnerOIDCPosts"
    model.syncPluralName = "OwnerOIDCPosts"

    model.fields(
      .id(),
      .field(ownerOIDCPost.name, is: .required, ofType: .string),
      .field(ownerOIDCPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ownerOIDCPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
