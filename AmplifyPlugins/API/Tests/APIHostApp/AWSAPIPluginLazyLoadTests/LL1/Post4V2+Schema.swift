//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post4V2 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let post4V2 = Post4V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Post4V2s"

    model.attributes(
      .primaryKey(fields: [post4V2.id])
    )

    model.fields(
      .field(post4V2.id, is: .required, ofType: .string),
      .field(post4V2.title, is: .required, ofType: .string),
      .hasMany(post4V2.comments, is: .optional, ofType: Comment4V2.self, associatedWith: Comment4V2.keys.post),
      .field(post4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }

    class Path: ModelPath<Post4V2> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Post4V2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Post4V2 {
    public var id: FieldPath<String> { id() }
    var title: FieldPath<String> { string("title") }
    var comments: ModelPath<Comment4V2> { Comment4V2.Path(name: "comments", isCollection: true, parent: self) }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
}
