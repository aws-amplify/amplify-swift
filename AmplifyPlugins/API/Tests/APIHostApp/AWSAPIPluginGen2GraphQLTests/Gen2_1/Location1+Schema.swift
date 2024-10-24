//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Location1 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case lat
    case long
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let location1 = Location1.keys

    model.listPluralName = "Location1s"
    model.syncPluralName = "Location1s"

    model.fields(
      .field(location1.lat, is: .optional, ofType: .double),
      .field(location1.long, is: .optional, ofType: .double)
    )
    }
}
