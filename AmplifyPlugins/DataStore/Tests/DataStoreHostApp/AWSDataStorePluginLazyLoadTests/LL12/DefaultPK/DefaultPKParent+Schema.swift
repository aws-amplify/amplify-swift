//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension DefaultPKParent {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case children
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let defaultPKParent = DefaultPKParent.keys

    model.pluralName = "DefaultPKParents"

    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [defaultPKParent.id])
    )

    model.fields(
      .field(defaultPKParent.id, is: .required, ofType: .string),
      .field(defaultPKParent.content, is: .optional, ofType: .string),
      .hasMany(defaultPKParent.children, is: .optional, ofType: DefaultPKChild.self, associatedWith: DefaultPKChild.keys.parent),
      .field(defaultPKParent.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(defaultPKParent.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<DefaultPKParent> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension DefaultPKParent: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == DefaultPKParent {
  var id: FieldPath<String>   {
      string("id")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var children: ModelPath<DefaultPKChild>   {
      DefaultPKChild.Path(name: "children", isCollection: true, parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
