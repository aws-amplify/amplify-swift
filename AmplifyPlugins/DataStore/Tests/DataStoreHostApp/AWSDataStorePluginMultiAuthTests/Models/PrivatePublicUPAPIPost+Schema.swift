//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PrivatePublicUPAPIPost {
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
    let privatePublicUPAPIPost = PrivatePublicUPAPIPost.keys

    model.authRules = [
      rule(allow: .private, provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivatePublicUPAPIPosts"
    model.syncPluralName = "PrivatePublicUPAPIPosts"

    model.fields(
      .id(),
      .field(privatePublicUPAPIPost.name, is: .required, ofType: .string),
      .field(privatePublicUPAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privatePublicUPAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
