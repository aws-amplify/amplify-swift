//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Project1 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case projectId
    case name
    case team
    case createdAt
    case updatedAt
    case project1TeamTeamId
    case project1TeamName
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let project1 = Project1.keys

    model.pluralName = "Project1s"

    model.attributes(
      .index(fields: ["projectId", "name"], name: nil),
      .primaryKey(fields: [project1.projectId, project1.name])
    )

    model.fields(
      .field(project1.projectId, is: .required, ofType: .string),
      .field(project1.name, is: .required, ofType: .string),
      .hasOne(project1.team, is: .optional, ofType: Team1.self, associatedWith: Team1.keys.project, targetNames: ["project1TeamTeamId", "project1TeamName"]),
      .field(project1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project1.project1TeamTeamId, is: .optional, ofType: .string),
      .field(project1.project1TeamName, is: .optional, ofType: .string)
    )
    }
    class Path: ModelPath<Project1> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Project1: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Project1.IdentifierProtocol {
  static func identifier(
    projectId: String,
    name: String
  ) -> Self {
    .make(fields: [(name: "projectId", value: projectId), (name: "name", value: name)])
  }
}
public extension ModelPath where ModelType == Project1 {
  var projectId: FieldPath<String>   {
      string("projectId")
    }
  var name: FieldPath<String>   {
      string("name")
    }
  var team: ModelPath<Team1>   {
      Team1.Path(name: "team", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
  var project1TeamTeamId: FieldPath<String>   {
      string("project1TeamTeamId")
    }
  var project1TeamName: FieldPath<String>   {
      string("project1TeamName")
    }
}
