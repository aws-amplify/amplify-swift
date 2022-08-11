//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PrivatePublicIAMAPIPost {
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
    let privatePublicIAMAPIPost = PrivatePublicIAMAPIPost.keys

    model.authRules = [
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivatePublicIAMAPIPosts"
    model.syncPluralName = "PrivatePublicIAMAPIPosts"

    model.fields(
      .id(),
      .field(privatePublicIAMAPIPost.name, is: .required, ofType: .string),
      .field(privatePublicIAMAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privatePublicIAMAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
