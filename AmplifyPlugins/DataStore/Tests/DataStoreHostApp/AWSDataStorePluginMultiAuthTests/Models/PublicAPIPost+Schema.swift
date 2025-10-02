//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PublicAPIPost {
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
    let publicAPIPost = PublicAPIPost.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PublicAPIPosts"
    model.syncPluralName = "PublicAPIPosts"

    model.fields(
      .id(),
      .field(publicAPIPost.name, is: .required, ofType: .string),
      .field(publicAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(publicAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
