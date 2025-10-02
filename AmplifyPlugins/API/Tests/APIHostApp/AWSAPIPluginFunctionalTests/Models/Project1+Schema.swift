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
    case id
    case name
    case team
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let project1 = Project1.keys

    model.pluralName = "Project1s"

    model.fields(
      .id(),
      .field(project1.name, is: .optional, ofType: .string),
      .belongsTo(project1.team, is: .optional, ofType: Team1.self, targetName: "project1TeamId"),
      .field(project1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
