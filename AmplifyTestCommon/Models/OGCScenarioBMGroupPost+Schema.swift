//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension OGCScenarioBMGroupPost {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case owner
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
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
