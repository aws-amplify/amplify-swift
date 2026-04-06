//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension OwnerPrivateUPIAMPost {
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
    let ownerPrivateUPIAMPost = OwnerPrivateUPIAMPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OwnerPrivateUPIAMPosts"
    model.syncPluralName = "OwnerPrivateUPIAMPosts"

    model.fields(
      .id(),
      .field(ownerPrivateUPIAMPost.name, is: .required, ofType: .string),
      .field(ownerPrivateUPIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ownerPrivateUPIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
