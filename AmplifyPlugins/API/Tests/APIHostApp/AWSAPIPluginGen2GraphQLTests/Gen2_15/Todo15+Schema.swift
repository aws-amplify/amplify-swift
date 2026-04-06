//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Todo15 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case owners
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let todo15 = Todo15.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owners", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Todo15s"
    model.syncPluralName = "Todo15s"

    model.attributes(
      .primaryKey(fields: [todo15.id])
    )

    model.fields(
      .field(todo15.id, is: .required, ofType: .string),
      .field(todo15.content, is: .optional, ofType: .string),
      .field(todo15.owners, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(todo15.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo15.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Todo15> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo15: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Todo15 {
  var id: FieldPath<String>   {
      string("id")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var owners: FieldPath<String>   {
      string("owners")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
