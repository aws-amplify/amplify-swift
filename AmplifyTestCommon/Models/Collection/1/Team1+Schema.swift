//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Team1 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let team1 = Team1.keys

    model.listPluralName = "Team1s"
    model.syncPluralName = "Team1s"

    model.fields(
      .id(),
      .field(team1.name, is: .required, ofType: .string)
    )
    }
}
