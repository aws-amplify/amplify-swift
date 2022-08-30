//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case content
    case createdAt
    case updatedAt
    case draft
    case rating
    case status
    case comments
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post = Post.keys

    model.listPluralName = "Posts"
    model.syncPluralName = "Posts"

    model.fields(
      .id(),
      .field(post.title, is: .required, ofType: .string),
      .field(post.content, is: .required, ofType: .string),
      .field(post.createdAt, is: .required, ofType: .dateTime),
      .field(post.updatedAt, is: .optional, ofType: .dateTime),
      .field(post.draft, is: .optional, ofType: .bool),
      .field(post.rating, is: .optional, ofType: .double),
      .field(post.status, is: .optional, ofType: .enum(type: PostStatus.self)),
      .hasMany(post.comments, is: .optional, ofType: Comment.self, associatedWith: Comment.keys.post)
    )
  }

  public class Path : ModelPath<Post> {}

  public static var rootPath: PropertyContainerPath? { Path() }

}

extension ModelPath where ModelType == Post {
    var id: FieldPath<String> { id() }
    var title: FieldPath<String> { string("title") }
    var content: FieldPath<String> { string("content") }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
    var draft: FieldPath<Bool> { bool("draft") }
    var comments: ModelPath<Comment> { Comment.Path(name: "comments", isCollection: true, parent: self) }
}
