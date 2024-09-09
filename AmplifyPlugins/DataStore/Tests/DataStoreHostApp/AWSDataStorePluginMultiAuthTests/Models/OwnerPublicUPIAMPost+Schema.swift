//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension OwnerPublicUPIAMPost {
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
    let ownerPublicUPIAMPost = OwnerPublicUPIAMPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OwnerPublicUPIAMPosts"
    model.syncPluralName = "OwnerPublicUPIAMPosts"

    model.fields(
      .id(),
      .field(ownerPublicUPIAMPost.name, is: .required, ofType: .string),
      .field(ownerPublicUPIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ownerPublicUPIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
