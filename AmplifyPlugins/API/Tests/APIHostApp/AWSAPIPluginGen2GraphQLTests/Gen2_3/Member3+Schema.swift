//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Member3 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case team
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let member3 = Member3.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Member3s"
    model.syncPluralName = "Member3s"

    model.attributes(
      .primaryKey(fields: [member3.id])
    )

    model.fields(
      .field(member3.id, is: .required, ofType: .string),
      .field(member3.name, is: .required, ofType: .string),
      .belongsTo(member3.team, is: .optional, ofType: Team3.self, targetNames: ["teamId"]),
      .field(member3.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(member3.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Member3> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Member3: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Member3 {
  var id: FieldPath<String>   {
      string("id")
    }
  var name: FieldPath<String>   {
      string("name")
    }
  var team: ModelPath<Team3>   {
      Team3.Path(name: "team", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
