//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Foundation
import Amplify

extension CoffeeShopLocation {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case address
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let coffeeShopLocation = CoffeeShopLocation.keys
    
    model.pluralName = "CoffeeShopLocations"
    
    model.fields(
      .id(),
      .field(coffeeShopLocation.address, is: .required, ofType: .string)
    )
    }
}

