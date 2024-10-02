//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PublicIAMPost {
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
    let publicIAMPost = PublicIAMPost.keys

    model.authRules = [
      rule(allow: .public, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PublicIAMPosts"
    model.syncPluralName = "PublicIAMPosts"

    model.fields(
      .id(),
      .field(publicIAMPost.name, is: .required, ofType: .string),
      .field(publicIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(publicIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
