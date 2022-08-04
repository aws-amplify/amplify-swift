//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Menu {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case menuType
    case restaurant
    case dishes
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let menu = Menu.keys

    model.listPluralName = "Menus"
    model.syncPluralName = "Menus"

    model.fields(
      .id(),
      .field(menu.name, is: .required, ofType: .string),
      .field(menu.menuType, is: .optional, ofType: .enum(type: MenuType.self)),
      .belongsTo(menu.restaurant, is: .optional, ofType: Restaurant.self, targetName: "menuRestaurantId"),
      .hasMany(menu.dishes, is: .optional, ofType: Dish.self, associatedWith: Dish.keys.menu)
    )
    }
}
