//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension DefaultPKChild {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case parent
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let defaultPKChild = DefaultPKChild.keys

    model.pluralName = "DefaultPKChildren"

    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [defaultPKChild.id])
    )

    model.fields(
      .field(defaultPKChild.id, is: .required, ofType: .string),
      .field(defaultPKChild.content, is: .optional, ofType: .string),
      .belongsTo(defaultPKChild.parent, is: .optional, ofType: DefaultPKParent.self, targetNames: ["defaultPKParentChildrenId"]),
      .field(defaultPKChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(defaultPKChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<DefaultPKChild> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension DefaultPKChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == DefaultPKChild {
  var id: FieldPath<String>   {
      string("id")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var parent: ModelPath<DefaultPKParent>   {
      DefaultPKParent.Path(name: "parent", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
