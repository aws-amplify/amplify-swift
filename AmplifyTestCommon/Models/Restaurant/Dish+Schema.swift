//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Dish {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case dishName
    case menu
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let dish = Dish.keys

    model.listPluralName = "Dishes"
    model.syncPluralName = "Dishes"

    model.fields(
      .id(),
      .field(dish.dishName, is: .optional, ofType: .string),
      .belongsTo(dish.menu, is: .optional, ofType: Menu.self, targetName: "dishMenuId")
    )
    }
}
