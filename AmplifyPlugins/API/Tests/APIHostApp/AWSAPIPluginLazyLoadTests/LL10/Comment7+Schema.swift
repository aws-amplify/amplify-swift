//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Comment7 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case commentId
    case content
    case post
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let comment7 = Comment7.keys

    model.pluralName = "Comment7s"

    model.attributes(
      .index(fields: ["commentId", "content"], name: nil),
      .index(fields: ["postId", "postTitle"], name: "byPost"),
      .primaryKey(fields: [comment7.commentId, comment7.content])
    )

    model.fields(
      .field(comment7.commentId, is: .required, ofType: .string),
      .field(comment7.content, is: .required, ofType: .string),
      .belongsTo(comment7.post, is: .optional, ofType: Post7.self, targetNames: ["postId", "postTitle"]),
      .field(comment7.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment7.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Comment7> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment7: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Comment7.IdentifierProtocol {
  static func identifier(
    commentId: String,
    content: String
  ) -> Self {
    .make(fields: [(name: "commentId", value: commentId), (name: "content", value: content)])
  }
}
public extension ModelPath where ModelType == Comment7 {
  var commentId: FieldPath<String>   {
      string("commentId")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var post: ModelPath<Post7>   {
      Post7.Path(name: "post", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
