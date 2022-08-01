//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension GroupPublicUPIAMPost {
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
    let groupPublicUPIAMPost = GroupPublicUPIAMPost.keys

    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admins"], provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "GroupPublicUPIAMPosts"
    model.syncPluralName = "GroupPublicUPIAMPosts"

    model.fields(
      .id(),
      .field(groupPublicUPIAMPost.name, is: .required, ofType: .string),
      .field(groupPublicUPIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(groupPublicUPIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
