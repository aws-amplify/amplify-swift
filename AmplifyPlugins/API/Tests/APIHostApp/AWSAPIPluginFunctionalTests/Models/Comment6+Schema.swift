//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Comment6 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case post
    case content
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let comment6 = Comment6.keys

    model.pluralName = "Comment6s"

    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost")
    )

    model.fields(
      .id(),
      .belongsTo(comment6.post, is: .optional, ofType: Post6.self, targetName: "postID"),
      .field(comment6.content, is: .required, ofType: .string),
      .field(comment6.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment6.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
