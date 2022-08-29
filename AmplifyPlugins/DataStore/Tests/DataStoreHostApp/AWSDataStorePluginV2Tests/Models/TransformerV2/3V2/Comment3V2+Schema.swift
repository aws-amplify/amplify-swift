//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment3V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case postID
    case content
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment3V2 = Comment3V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Comment3V2s"

    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost3")
    )

    model.fields(
      .id(),
      .field(comment3V2.postID, is: .required, ofType: .string),
      .field(comment3V2.content, is: .required, ofType: .string),
      .field(comment3V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment3V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
