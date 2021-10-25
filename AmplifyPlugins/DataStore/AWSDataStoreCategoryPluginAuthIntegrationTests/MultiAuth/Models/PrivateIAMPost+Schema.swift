//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PrivateIAMPost {
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
    let privateIAMPost = PrivateIAMPost.keys

    model.authRules = [
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivateIAMPosts"
    model.syncPluralName = "PrivateIAMPosts"

    model.fields(
      .id(),
      .field(privateIAMPost.name, is: .required, ofType: .string),
      .field(privateIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privateIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
