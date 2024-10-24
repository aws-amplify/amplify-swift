//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Comment8V2 {
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
    let comment8V2 = Comment8V2.keys

    model.pluralName = "Comment8V2s"

    model.attributes(
      .index(fields: ["postId"], name: "commentByPost"),
      .primaryKey(fields: [comment8V2.id])
    )

    model.fields(
      .field(comment8V2.id, is: .required, ofType: .string),
      .field(comment8V2.content, is: .optional, ofType: .string),
      .belongsTo(comment8V2.post, is: .optional, ofType: Post8V2.self, targetNames: ["postId"]),
      .field(comment8V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment8V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }

    class Path: ModelPath<Comment8V2> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment8V2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Comment8V2 {
    var id: FieldPath<String> { id() }
    var content: FieldPath<String> { string("content") }
    var post: ModelPath<Post8V2> { Post8V2.Path(name: "post", parent: self) }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
}
