//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension CommentWithCompositeKey {
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
    let comment22 = CommentWithCompositeKey.keys

    model.pluralName = "CommentWithCompositeKeys"

    model.attributes(
      .index(fields: ["id", "content"], name: nil),
      .primaryKey(fields: [comment22.id, comment22.content])
    )

    model.fields(
      .field(comment22.id, is: .required, ofType: .string),
      .field(comment22.content, is: .required, ofType: .string),
      .belongsTo(comment22.post, is: .optional, ofType: PostWithCompositeKey.self, targetNames: ["postWithCompositeKeyCommentsId", "postWithCompositeKeyCommentsTitle"]),
      .field(comment22.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment22.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension CommentWithCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias Identifier = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension CommentWithCompositeKey.Identifier {
  public static func identifier(id: String,
      content: String) -> Self {
    .make(fields: [(name: "id", value: id), (name: "content", value: content)])
  }
}
