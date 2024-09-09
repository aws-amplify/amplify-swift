//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension HasOneChild {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let hasOneChild = HasOneChild.keys

    model.pluralName = "HasOneChildren"

    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [hasOneChild.id])
    )

    model.fields(
      .field(hasOneChild.id, is: .required, ofType: .string),
      .field(hasOneChild.content, is: .optional, ofType: .string),
      .field(hasOneChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(hasOneChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<HasOneChild> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension HasOneChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == HasOneChild {
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
