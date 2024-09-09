//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post4 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case postId
    case title
    case comments
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let post4 = Post4.keys

    model.pluralName = "Post4s"

    model.attributes(
      .index(fields: ["postId", "title"], name: nil),
      .primaryKey(fields: [post4.postId, post4.title])
    )

    model.fields(
      .field(post4.postId, is: .required, ofType: .string),
      .field(post4.title, is: .required, ofType: .string),
      .hasMany(post4.comments, is: .optional, ofType: Comment4.self, associatedFields: [Comment4.keys.post4CommentsPostId, Comment4.keys.post4CommentsTitle]),
      .field(post4.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post4.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Post4> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Post4: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Post4.IdentifierProtocol {
  static func identifier(
    postId: String,
    title: String
  ) -> Self {
    .make(fields: [(name: "postId", value: postId), (name: "title", value: title)])
  }
}
public extension ModelPath where ModelType == Post4 {
  var postId: FieldPath<String>   {
      string("postId")
    }
  var title: FieldPath<String>   {
      string("title")
    }
  var comments: ModelPath<Comment4>   {
      Comment4.Path(name: "comments", isCollection: true, parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
