//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment4V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment4V2 = Comment4V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Comment4V2s"

    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost4")
    )

    model.fields(
      .id(),
      .field(comment4V2.content, is: .required, ofType: .string),
      .belongsTo(comment4V2.post, is: .optional, ofType: Post4V2.self, targetName: "postID"),
      .field(comment4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
