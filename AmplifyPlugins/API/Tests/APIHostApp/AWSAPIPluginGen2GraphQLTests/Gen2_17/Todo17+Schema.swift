//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Todo17 {
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
    let todo17 = Todo17.keys

    model.authRules = [
      rule(allow: .private, provider: .iam, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Todo17s"
    model.syncPluralName = "Todo17s"

    model.attributes(
      .primaryKey(fields: [todo17.id])
    )

    model.fields(
      .field(todo17.id, is: .required, ofType: .string),
      .field(todo17.content, is: .optional, ofType: .string),
      .field(todo17.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo17.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Todo17> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo17: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Todo17 {
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
