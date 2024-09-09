//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension OwnerUPPost {
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
    let ownerUPPost = OwnerUPPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OwnerUPPosts"
    model.syncPluralName = "OwnerUPPosts"

    model.fields(
      .id(),
      .field(ownerUPPost.name, is: .required, ofType: .string),
      .field(ownerUPPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ownerUPPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
