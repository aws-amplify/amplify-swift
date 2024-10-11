//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Nested {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case valueOne
    case valueTwo
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let nested = Nested.keys

    model.listPluralName = "Nesteds"
    model.syncPluralName = "Nesteds"

    model.fields(
      .field(nested.valueOne, is: .optional, ofType: .int),
      .field(nested.valueTwo, is: .optional, ofType: .string)
    )
    }
}
