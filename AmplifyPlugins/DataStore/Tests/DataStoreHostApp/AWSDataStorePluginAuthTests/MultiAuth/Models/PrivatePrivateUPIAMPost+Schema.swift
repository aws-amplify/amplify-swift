//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PrivatePrivateUPIAMPost {
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
    let privatePrivateUPIAMPost = PrivatePrivateUPIAMPost.keys

    model.authRules = [
      rule(allow: .private, provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivatePrivateUPIAMPosts"
    model.syncPluralName = "PrivatePrivateUPIAMPosts"

    model.fields(
      .id(),
      .field(privatePrivateUPIAMPost.name, is: .required, ofType: .string),
      .field(privatePrivateUPIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privatePrivateUPIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
