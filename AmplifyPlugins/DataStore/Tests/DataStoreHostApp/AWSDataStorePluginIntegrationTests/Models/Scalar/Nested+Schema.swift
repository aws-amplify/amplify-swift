//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Nested {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case valueOne
    case valueTwo
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let nested = Nested.keys

    model.listPluralName = "Nesteds"
    model.syncPluralName = "Nesteds"

    model.fields(
      .field(nested.valueOne, is: .optional, ofType: .int),
      .field(nested.valueTwo, is: .optional, ofType: .string)
    )
    }
}
