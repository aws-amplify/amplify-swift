//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension OwnerPrivatePublicUPIAMAPIPost {
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
    let ownerPrivatePublicUPIAMAPIPost = OwnerPrivatePublicUPIAMAPIPost.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "OwnerPrivatePublicUPIAMAPIPosts"
    model.syncPluralName = "OwnerPrivatePublicUPIAMAPIPosts"

    model.fields(
      .id(),
      .field(ownerPrivatePublicUPIAMAPIPost.name, is: .required, ofType: .string),
      .field(ownerPrivatePublicUPIAMAPIPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ownerPrivatePublicUPIAMAPIPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
