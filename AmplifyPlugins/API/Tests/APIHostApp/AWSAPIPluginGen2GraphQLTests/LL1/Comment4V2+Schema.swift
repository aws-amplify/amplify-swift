//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Comment4V2 {
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
    let comment4V2 = Comment4V2.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Comment4V2s"
    model.syncPluralName = "Comment4V2s"

    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [comment4V2.id])
    )

    model.fields(
      .field(comment4V2.id, is: .required, ofType: .string),
      .field(comment4V2.content, is: .required, ofType: .string),
      .belongsTo(comment4V2.post, is: .optional, ofType: Post4V2.self, targetNames: ["postID"]),
      .field(comment4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Comment4V2> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment4V2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Comment4V2 {
  var id: FieldPath<String>   {
      string("id")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var post: ModelPath<Post4V2>   {
      Post4V2.Path(name: "post", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
