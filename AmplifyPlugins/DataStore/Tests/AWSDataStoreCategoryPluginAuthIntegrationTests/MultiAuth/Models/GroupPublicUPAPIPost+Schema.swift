//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension GroupPublicUPAPIPost {
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
    let groupPublicUPAPIPost = GroupPublicUPAPIPost.keys

    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admins"], provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "GroupPublicUPAPIPosts"
    model.syncPluralName = "GroupPublicUPAPIPosts"

    model.fields(
      .id(),
      .field(groupPublicUPAPIPost.name, is: .required, ofType: .string),
      .field(groupPublicUPAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(groupPublicUPAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
