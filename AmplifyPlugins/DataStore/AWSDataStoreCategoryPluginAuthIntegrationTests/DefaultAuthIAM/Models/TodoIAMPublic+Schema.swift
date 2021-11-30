//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoIAMPublic {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let todoIAMPublic = TodoIAMPublic.keys

    model.authRules = [
      rule(allow: .public, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "TodoIAMPublics"

    model.fields(
      .id(),
      .field(todoIAMPublic.title, is: .required, ofType: .string),
      .field(todoIAMPublic.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoIAMPublic.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
