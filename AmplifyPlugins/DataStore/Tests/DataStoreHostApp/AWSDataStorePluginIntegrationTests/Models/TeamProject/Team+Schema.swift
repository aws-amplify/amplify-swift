//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Team {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let team = Team.keys

    model.listPluralName = "Teams"
    model.syncPluralName = "Teams"

    model.fields(
      .id(),
      .field(team.name, is: .required, ofType: .string)
    )
    }
}
