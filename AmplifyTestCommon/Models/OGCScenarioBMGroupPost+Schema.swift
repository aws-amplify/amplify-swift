//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension OGCScenarioBMGroupPost {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case title
    case owner
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let oGCScenarioBMGroupPost = OGCScenarioBMGroupPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", operations: [.create, .update, .delete, .read]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admins", "HR"], operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OGCScenarioBMGroupPosts"
    model.syncPluralName = "OGCScenarioBMGroupPosts"

    model.fields(
      .id(),
      .field(oGCScenarioBMGroupPost.title, is: .required, ofType: .string),
      .field(oGCScenarioBMGroupPost.owner, is: .optional, ofType: .string)
    )
    }
}
