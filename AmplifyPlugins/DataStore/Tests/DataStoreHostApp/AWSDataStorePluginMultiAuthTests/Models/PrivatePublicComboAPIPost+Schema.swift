//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PrivatePublicComboAPIPost {
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
    let privatePublicComboAPIPost = PrivatePublicComboAPIPost.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivatePublicComboAPIPosts"
    model.syncPluralName = "PrivatePublicComboAPIPosts"

    model.fields(
      .id(),
      .field(privatePublicComboAPIPost.name, is: .required, ofType: .string),
      .field(privatePublicComboAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privatePublicComboAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
