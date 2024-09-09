//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
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

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "CommentWithCompositeKeys"
    model.syncPluralName = "CommentWithCompositeKeys"

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
    class Path: ModelPath<CommentWithCompositeKey> { }

    static var rootPath: PropertyContainerPath? { Path() }
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
public extension ModelPath where ModelType == CommentWithCompositeKey {
  var id: FieldPath<String>   {
      string("id")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var post: ModelPath<PostWithCompositeKey>   {
      PostWithCompositeKey.Path(name: "post", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
