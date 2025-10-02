//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Todo5 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case completed
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let todo5 = Todo5.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Todo5s"
    model.syncPluralName = "Todo5s"

    model.attributes(
      .primaryKey(fields: [todo5.id])
    )

    model.fields(
      .field(todo5.id, is: .required, ofType: .string),
      .field(todo5.content, is: .optional, ofType: .string),
      .field(todo5.completed, is: .optional, ofType: .bool),
      .field(todo5.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo5.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Todo5> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo5: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Todo5 {
  var id: FieldPath<String>   {
      string("id")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var completed: FieldPath<Bool>   {
      bool("completed")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
