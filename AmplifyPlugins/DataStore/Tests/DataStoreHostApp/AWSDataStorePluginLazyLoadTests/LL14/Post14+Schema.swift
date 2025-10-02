//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post14 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case title
    case rating
    case status
    case comments
    case author
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let post14 = Post14.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Post14s"

    model.attributes(
      .primaryKey(fields: [post14.id])
    )

    model.fields(
      .field(post14.id, is: .required, ofType: .string),
      .field(post14.title, is: .required, ofType: .string),
      .field(post14.rating, is: .required, ofType: .int),
      .field(post14.status, is: .required, ofType: .enum(type: PostStatus.self)),
      .hasMany(post14.comments, is: .optional, ofType: Comment14.self, associatedWith: Comment14.keys.post),
      .belongsTo(post14.author, is: .required, ofType: User14.self, targetNames: ["user14PostsId"]),
      .field(post14.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post14.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Post14> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Post14: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Post14 {
  var id: FieldPath<String>   {
      string("id")
    }
  var title: FieldPath<String>   {
      string("title")
    }
  var rating: FieldPath<Int>   {
      int("rating")
    }
  var comments: ModelPath<Comment14>   {
      Comment14.Path(name: "comments", isCollection: true, parent: self)
    }
  var author: ModelPath<User14>   {
      User14.Path(name: "author", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
