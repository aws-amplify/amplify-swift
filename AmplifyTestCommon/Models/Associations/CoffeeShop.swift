//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Foundation
import Amplify

public struct CoffeeShop: Model {
  public let id: String
  public var isOpen: Bool?
  public var location: CoffeeShopLocation?
  
  public init(id: String = UUID().uuidString,
      isOpen: Bool? = nil,
      location: CoffeeShopLocation? = nil) {
      self.id = id
      self.isOpen = isOpen
      self.location = location
  }
}
