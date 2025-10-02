//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Project {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case team
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let project = Project.keys

    model.listPluralName = "Projects"
    model.syncPluralName = "Projects"

    model.fields(
      .id(),
      .field(project.name, is: .optional, ofType: .string),
      .belongsTo(project.team, is: .optional, ofType: Team.self, targetName: "projectTeamId")
    )
    }
}
