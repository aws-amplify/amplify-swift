//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension GroupPrivateUPIAMPost {
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
    let groupPrivateUPIAMPost = GroupPrivateUPIAMPost.keys

    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admins"], provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "GroupPrivateUPIAMPosts"
    model.syncPluralName = "GroupPrivateUPIAMPosts"

    model.fields(
      .id(),
      .field(groupPrivateUPIAMPost.name, is: .required, ofType: .string),
      .field(groupPrivateUPIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(groupPrivateUPIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
