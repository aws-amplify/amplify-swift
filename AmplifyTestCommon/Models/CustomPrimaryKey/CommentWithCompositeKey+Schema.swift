//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension CommentWithCompositeKey {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let commentWithCompositeKey = CommentWithCompositeKey.keys

    model.pluralName = "CommentWithCompositeKeys"

    model.attributes(
      .index(fields: ["id", "content"], name: nil),
      .primaryKey(fields: [commentWithCompositeKey.id, commentWithCompositeKey.content])
    )

    model.fields(
      .field(commentWithCompositeKey.id, is: .required, ofType: .string),
      .field(commentWithCompositeKey.content, is: .required, ofType: .string),
      .belongsTo(commentWithCompositeKey.post, is: .optional, ofType: PostWithCompositeKey.self, targetNames: ["postWithCompositeKeyCommentsId", "postWithCompositeKeyCommentsTitle"]),
      .field(commentWithCompositeKey.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(commentWithCompositeKey.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension CommentWithCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension CommentWithCompositeKey.IdentifierProtocol {
  static func identifier(
    id: String,
    content: String
  ) -> Self {
    .make(fields: [(name: "id", value: id), (name: "content", value: content)])
  }
}
