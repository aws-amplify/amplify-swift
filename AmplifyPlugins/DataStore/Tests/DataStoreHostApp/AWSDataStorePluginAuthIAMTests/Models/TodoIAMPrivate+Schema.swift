//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension TodoIAMPrivate {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case title
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let todoIAMPrivate = TodoIAMPrivate.keys

    model.authRules = [
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "TodoIAMPrivates"

    model.fields(
      .id(),
      .field(todoIAMPrivate.title, is: .required, ofType: .string),
      .field(todoIAMPrivate.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoIAMPrivate.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
