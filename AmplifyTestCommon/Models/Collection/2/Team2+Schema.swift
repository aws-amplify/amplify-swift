//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Team2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let team2 = Team2.keys

    model.listPluralName = "Team2s"
    model.syncPluralName = "Team2s"

    model.fields(
      .id(),
      .field(team2.name, is: .required, ofType: .string)
    )
    }
}
