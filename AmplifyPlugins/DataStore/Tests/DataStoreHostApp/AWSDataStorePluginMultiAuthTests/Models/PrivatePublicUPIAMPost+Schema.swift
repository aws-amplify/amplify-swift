//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PrivatePublicUPIAMPost {
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
    let privatePublicUPIAMPost = PrivatePublicUPIAMPost.keys

    model.authRules = [
      rule(allow: .private, provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivatePublicUPIAMPosts"
    model.syncPluralName = "PrivatePublicUPIAMPosts"

    model.fields(
      .id(),
      .field(privatePublicUPIAMPost.name, is: .required, ofType: .string),
      .field(privatePublicUPIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privatePublicUPIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
