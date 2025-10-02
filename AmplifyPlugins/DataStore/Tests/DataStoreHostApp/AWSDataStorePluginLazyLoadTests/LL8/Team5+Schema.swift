//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Team5 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case teamId
    case name
    case project
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let team5 = Team5.keys

    model.pluralName = "Team5s"

    model.attributes(
      .index(fields: ["teamId", "name"], name: nil),
      .primaryKey(fields: [team5.teamId, team5.name])
    )

    model.fields(
      .field(team5.teamId, is: .required, ofType: .string),
      .field(team5.name, is: .required, ofType: .string),
      .belongsTo(team5.project, is: .optional, ofType: Project5.self, targetNames: ["projectId", "projectName"]),
      .field(team5.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team5.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }

    class Path: ModelPath<Team5> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Team5: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Team5.IdentifierProtocol {
  static func identifier(
    teamId: String,
    name: String
  ) -> Self {
    .make(fields: [(name: "teamId", value: teamId), (name: "name", value: name)])
  }
}

extension ModelPath where ModelType == Team5 {
    var teamId: FieldPath<String> { string("projectId") }
    var name: FieldPath<String> { string("name") }
    var project: ModelPath<Project5> { Project5.Path(name: "project", parent: self) }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
}
