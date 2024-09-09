//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension GroupUPPost {
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
    let groupUPPost = GroupUPPost.keys

    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admins"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "GroupUPPosts"
    model.syncPluralName = "GroupUPPosts"

    model.fields(
      .id(),
      .field(groupUPPost.name, is: .required, ofType: .string),
      .field(groupUPPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(groupUPPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
