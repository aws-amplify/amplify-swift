//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension GroupPrivatePublicUPIAMAPIPost {
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
    let groupPrivatePublicUPIAMAPIPost = GroupPrivatePublicUPIAMAPIPost.keys

    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admins"], provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "GroupPrivatePublicUPIAMAPIPosts"
    model.syncPluralName = "GroupPrivatePublicUPIAMAPIPosts"

    model.fields(
      .id(),
      .field(groupPrivatePublicUPIAMAPIPost.name, is: .required, ofType: .string),
      .field(groupPrivatePublicUPIAMAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(groupPrivatePublicUPIAMAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
