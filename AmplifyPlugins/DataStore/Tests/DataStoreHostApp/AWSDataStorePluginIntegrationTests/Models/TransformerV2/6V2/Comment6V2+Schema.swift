//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment6V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case post
    case content
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment6V2 = Comment6V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Comment6V2s"

    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost")
    )

    model.fields(
      .id(),
      .belongsTo(comment6V2.post, is: .optional, ofType: Post6V2.self, targetName: "postID"),
      .field(comment6V2.content, is: .required, ofType: .string),
      .field(comment6V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment6V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
