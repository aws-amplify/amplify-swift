//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PrivatePublicComboUPPost {
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
    let privatePublicComboUPPost = PrivatePublicComboUPPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivatePublicComboUPPosts"
    model.syncPluralName = "PrivatePublicComboUPPosts"

    model.fields(
      .id(),
      .field(privatePublicComboUPPost.name, is: .required, ofType: .string),
      .field(privatePublicComboUPPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privatePublicComboUPPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
