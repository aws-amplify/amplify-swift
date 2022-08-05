//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension CommentWithCompositeKeyAndIndex {
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
    let commentWithCompositeKeyAndIndex = CommentWithCompositeKeyAndIndex.keys

    model.pluralName = "CommentWithCompositeKeyAndIndices"

    model.attributes(
      .index(fields: ["id", "content"], name: nil),
      .index(fields: ["postID", "postTitle"], name: "byPost"),
      .primaryKey(fields: [commentWithCompositeKeyAndIndex.id, commentWithCompositeKeyAndIndex.content])
    )

    model.fields(
      .field(commentWithCompositeKeyAndIndex.id, is: .required, ofType: .string),
      .field(commentWithCompositeKeyAndIndex.content, is: .required, ofType: .string),
      .belongsTo(commentWithCompositeKeyAndIndex.post, is: .optional, ofType: PostWithCompositeKeyAndIndex.self, targetNames: ["postID", "postTitle"]),
      .field(commentWithCompositeKeyAndIndex.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(commentWithCompositeKeyAndIndex.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension CommentWithCompositeKeyAndIndex: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension CommentWithCompositeKeyAndIndex.IdentifierProtocol {
  public static func identifier(id: String,
      content: String) -> Self {
    .make(fields: [(name: "id", value: id), (name: "content", value: content)])
  }
}
