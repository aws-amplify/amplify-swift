//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Team1 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let team1 = Team1.keys

    model.listPluralName = "Team1s"
    model.syncPluralName = "Team1s"

    model.fields(
      .id(),
      .field(team1.name, is: .required, ofType: .string)
    )
    }
}
