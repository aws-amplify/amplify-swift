//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PrivatePublicPublicUPAPIIAMPost {
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
    let privatePublicPublicUPAPIIAMPost = PrivatePublicPublicUPAPIIAMPost.keys

    model.authRules = [
      rule(allow: .private, provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivatePublicPublicUPAPIIAMPosts"
    model.syncPluralName = "PrivatePublicPublicUPAPIIAMPosts"

    model.fields(
      .id(),
      .field(privatePublicPublicUPAPIIAMPost.name, is: .required, ofType: .string),
      .field(privatePublicPublicUPAPIIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privatePublicPublicUPAPIIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
