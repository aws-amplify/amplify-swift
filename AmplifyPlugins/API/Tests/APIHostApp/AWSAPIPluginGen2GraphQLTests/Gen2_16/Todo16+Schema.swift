//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Todo16 {
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
    let todo16 = Todo16.keys

    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Todo16s"
    model.syncPluralName = "Todo16s"

    model.attributes(
      .primaryKey(fields: [todo16.id])
    )

    model.fields(
      .field(todo16.id, is: .required, ofType: .string),
      .field(todo16.content, is: .optional, ofType: .string),
      .field(todo16.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo16.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Todo16> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo16: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Todo16 {
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
