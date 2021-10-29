//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PrivatePrivatePublicUPIAMIAMPost {
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
    let privatePrivatePublicUPIAMIAMPost = PrivatePrivatePublicUPIAMIAMPost.keys

    model.authRules = [
      rule(allow: .private, provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "PrivatePrivatePublicUPIAMIAMPosts"
    model.syncPluralName = "PrivatePrivatePublicUPIAMIAMPosts"

    model.fields(
      .id(),
      .field(privatePrivatePublicUPIAMIAMPost.name, is: .required, ofType: .string),
      .field(privatePrivatePublicUPIAMIAMPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(privatePrivatePublicUPIAMIAMPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
