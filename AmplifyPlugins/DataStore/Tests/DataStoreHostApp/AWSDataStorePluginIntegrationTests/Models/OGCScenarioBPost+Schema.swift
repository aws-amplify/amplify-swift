//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension OGCScenarioBPost {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case owner
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let oGCScenarioBPost = OGCScenarioBPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", operations: [.create, .update, .delete, .read]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admins"], operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OGCScenarioBPosts"
    model.syncPluralName = "OGCScenarioBPosts"

    model.fields(
      .id(),
      .field(oGCScenarioBPost.title, is: .required, ofType: .string),
      .field(oGCScenarioBPost.owner, is: .optional, ofType: .string)
    )
    }
}
