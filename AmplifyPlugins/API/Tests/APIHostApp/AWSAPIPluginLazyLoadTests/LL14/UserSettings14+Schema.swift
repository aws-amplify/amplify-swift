//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension UserSettings14 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case language
    case user
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let userSettings14 = UserSettings14.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "UserSettings14s"

    model.attributes(
      .primaryKey(fields: [userSettings14.id])
    )

    model.fields(
      .field(userSettings14.id, is: .required, ofType: .string),
      .field(userSettings14.language, is: .optional, ofType: .string),
      .belongsTo(userSettings14.user, is: .required, ofType: User14.self, targetNames: ["userSettings14UserId"]),
      .field(userSettings14.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(userSettings14.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<UserSettings14> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension UserSettings14: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == UserSettings14 {
  var id: FieldPath<String>   {
      string("id")
    }
  var language: FieldPath<String>   {
      string("language")
    }
  var user: ModelPath<User14>   {
      User14.Path(name: "user", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
