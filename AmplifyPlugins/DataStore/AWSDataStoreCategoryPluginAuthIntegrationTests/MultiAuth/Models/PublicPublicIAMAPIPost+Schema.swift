//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PublicPublicIAMAPIPost {
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
    let publicPublicIAMAPIPost = PublicPublicIAMAPIPost.keys

    model.authRules = [
      rule(allow: .public, provider: .iam, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PublicPublicIAMAPIPosts"
    model.syncPluralName = "PublicPublicIAMAPIPosts"

    model.fields(
      .id(),
      .field(publicPublicIAMAPIPost.name, is: .required, ofType: .string),
      .field(publicPublicIAMAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(publicPublicIAMAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
