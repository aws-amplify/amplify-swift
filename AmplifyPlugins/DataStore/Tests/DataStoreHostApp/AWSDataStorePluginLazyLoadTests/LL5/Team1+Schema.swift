//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Team1 {
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
    let team1 = Team1.keys

    model.pluralName = "Team1s"

    model.attributes(
      .index(fields: ["teamId", "name"], name: nil),
      .primaryKey(fields: [team1.teamId, team1.name])
    )

    model.fields(
      .field(team1.teamId, is: .required, ofType: .string),
      .field(team1.name, is: .required, ofType: .string),
      .belongsTo(team1.project, is: .optional, ofType: Project1.self, targetNames: ["team1ProjectProjectId", "team1ProjectName"]),
      .field(team1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Team1> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Team1: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Team1.IdentifierProtocol {
  static func identifier(
    teamId: String,
    name: String
  ) -> Self {
    .make(fields: [(name: "teamId", value: teamId), (name: "name", value: name)])
  }
}
public extension ModelPath where ModelType == Team1 {
  var teamId: FieldPath<String>   {
      string("teamId")
    }
  var name: FieldPath<String>   {
      string("name")
    }
  var project: ModelPath<Project1>   {
      Project1.Path(name: "project", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
