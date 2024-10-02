//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PrivateUPPost {
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
    let privateUPPost = PrivateUPPost.keys

    model.authRules = [
      rule(allow: .private, provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivateUPPosts"
    model.syncPluralName = "PrivateUPPosts"

    model.fields(
      .id(),
      .field(privateUPPost.name, is: .required, ofType: .string),
      .field(privateUPPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privateUPPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
