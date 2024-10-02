//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Person41 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case editedPosts
    case authoredPosts
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let person41 = Person41.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Person41s"
    model.syncPluralName = "Person41s"

    model.attributes(
      .primaryKey(fields: [person41.id])
    )

    model.fields(
      .field(person41.id, is: .required, ofType: .string),
      .field(person41.name, is: .optional, ofType: .string),
      .hasMany(person41.editedPosts, is: .optional, ofType: Post41.self, associatedFields: [Post41.keys.editor]),
      .hasMany(person41.authoredPosts, is: .optional, ofType: Post41.self, associatedFields: [Post41.keys.author]),
      .field(person41.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(person41.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Person41> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Person41: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Person41 {
  var id: FieldPath<String>   {
      string("id")
    }
  var name: FieldPath<String>   {
      string("name")
    }
  var editedPosts: ModelPath<Post41>   {
      Post41.Path(name: "editedPosts", isCollection: true, parent: self)
    }
  var authoredPosts: ModelPath<Post41>   {
      Post41.Path(name: "authoredPosts", isCollection: true, parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
