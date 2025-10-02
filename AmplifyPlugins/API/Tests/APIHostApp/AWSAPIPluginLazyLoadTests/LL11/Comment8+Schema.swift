//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Comment8 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case commentId
    case content
    case postId
    case postTitle
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let comment8 = Comment8.keys

    model.pluralName = "Comment8s"

    model.attributes(
      .index(fields: ["commentId", "content"], name: nil),
      .index(fields: ["postId", "postTitle"], name: "byPost"),
      .primaryKey(fields: [comment8.commentId, comment8.content])
    )

    model.fields(
      .field(comment8.commentId, is: .required, ofType: .string),
      .field(comment8.content, is: .required, ofType: .string),
      .field(comment8.postId, is: .optional, ofType: .string),
      .field(comment8.postTitle, is: .optional, ofType: .string),
      .field(comment8.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment8.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Comment8> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment8: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Comment8.IdentifierProtocol {
  static func identifier(
    commentId: String,
    content: String
  ) -> Self {
    .make(fields: [(name: "commentId", value: commentId), (name: "content", value: content)])
  }
}
public extension ModelPath where ModelType == Comment8 {
  var commentId: FieldPath<String>   {
      string("commentId")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var postId: FieldPath<String>   {
      string("postId")
    }
  var postTitle: FieldPath<String>   {
      string("postTitle")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
