//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Foundation
import Amplify

extension CoffeeShop {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case isOpen
    case location
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let coffeeShop = CoffeeShop.keys
    
    model.pluralName = "CoffeeShops"
    
    model.fields(
      .id(),
      .field(coffeeShop.isOpen, is: .optional, ofType: .bool),
      .hasOne(coffeeShop.location, is: .optional, ofType: CoffeeShopLocation.self, associatedWith: CoffeeShopLocation.keys.id, targetName: "locationID")
    )
    }
}
