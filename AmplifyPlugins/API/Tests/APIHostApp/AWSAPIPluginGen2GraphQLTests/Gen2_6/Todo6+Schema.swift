//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Todo6 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case todoId
    case content
    case completed
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let todo6 = Todo6.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Todo6s"
    model.syncPluralName = "Todo6s"

    model.attributes(
      .index(fields: ["todoId"], name: nil),
      .primaryKey(fields: [todo6.todoId])
    )

    model.fields(
      .field(todo6.todoId, is: .required, ofType: .string),
      .field(todo6.content, is: .optional, ofType: .string),
      .field(todo6.completed, is: .optional, ofType: .bool),
      .field(todo6.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo6.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Todo6> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo6: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Todo6.IdentifierProtocol {
  static func identifier(todoId: String) -> Self {
    .make(fields: [(name: "todoId", value: todoId)])
  }
}
public extension ModelPath where ModelType == Todo6 {
  var todoId: FieldPath<String>   {
      string("todoId")
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
