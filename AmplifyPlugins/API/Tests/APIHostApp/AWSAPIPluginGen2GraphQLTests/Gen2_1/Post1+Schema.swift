//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post1 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case location
    case content
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let post1 = Post1.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Post1s"
    model.syncPluralName = "Post1s"

    model.attributes(
      .primaryKey(fields: [post1.id])
    )

    model.fields(
      .field(post1.id, is: .required, ofType: .string),
      .field(post1.location, is: .optional, ofType: .embedded(type: Location1.self)),
      .field(post1.content, is: .optional, ofType: .string),
      .field(post1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Post1> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Post1: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Post1 {
  var id: FieldPath<String>   {
      string("id")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
