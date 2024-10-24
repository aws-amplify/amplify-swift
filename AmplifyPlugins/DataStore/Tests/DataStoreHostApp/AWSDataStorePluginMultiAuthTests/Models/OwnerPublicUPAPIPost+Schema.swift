//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension OwnerPublicUPAPIPost {
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
    let ownerPublicUPAPIPost = OwnerPublicUPAPIPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OwnerPublicUPAPIPosts"
    model.syncPluralName = "OwnerPublicUPAPIPosts"

    model.fields(
      .id(),
      .field(ownerPublicUPAPIPost.name, is: .required, ofType: .string),
      .field(ownerPublicUPAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ownerPublicUPAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
