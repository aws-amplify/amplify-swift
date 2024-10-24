//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension HasOneParent {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case child
    case createdAt
    case updatedAt
    case hasOneParentChildId
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let hasOneParent = HasOneParent.keys

    model.pluralName = "HasOneParents"

    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [hasOneParent.id])
    )

    model.fields(
      .field(hasOneParent.id, is: .required, ofType: .string),
      .hasOne(hasOneParent.child, is: .optional, ofType: HasOneChild.self, associatedWith: HasOneChild.keys.id, targetNames: ["hasOneParentChildId"]),
      .field(hasOneParent.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(hasOneParent.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(hasOneParent.hasOneParentChildId, is: .optional, ofType: .string)
    )
    }
    class Path: ModelPath<HasOneParent> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension HasOneParent: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == HasOneParent {
  var id: FieldPath<String>   {
      string("id")
    }
  var child: ModelPath<HasOneChild>   {
      HasOneChild.Path(name: "child", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
  var hasOneParentChildId: FieldPath<String>   {
      string("hasOneParentChildId")
    }
}
