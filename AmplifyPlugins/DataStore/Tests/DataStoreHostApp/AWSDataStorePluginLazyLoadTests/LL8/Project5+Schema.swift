//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Project5 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case projectId
    case name
    case team
    case teamId
    case teamName
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let project5 = Project5.keys

    model.pluralName = "Project5s"

    model.attributes(
      .index(fields: ["projectId", "name"], name: nil),
      .primaryKey(fields: [project5.projectId, project5.name])
    )

    model.fields(
      .field(project5.projectId, is: .required, ofType: .string),
      .field(project5.name, is: .required, ofType: .string),
      .hasOne(project5.team, is: .optional, ofType: Team5.self, associatedWith: Team5.keys.project, targetNames: ["teamId", "teamName"]),
      .field(project5.teamId, is: .optional, ofType: .string),
      .field(project5.teamName, is: .optional, ofType: .string),
      .field(project5.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project5.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }

    class Path: ModelPath<Project5> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Project5: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Project5.IdentifierProtocol {
  static func identifier(
    projectId: String,
    name: String
  ) -> Self {
    .make(fields: [(name: "projectId", value: projectId), (name: "name", value: name)])
  }
}

extension ModelPath where ModelType == Project5 {
    var projectId: FieldPath<String> { string("projectId") }
    var name: FieldPath<String> { string("name") }
    var team: ModelPath<Team5> { Team5.Path(name: "team", parent: self) }
    var teamId: FieldPath<String> { string("teamId") }
    var teamName: FieldPath<String> { string("teamName") }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
}
