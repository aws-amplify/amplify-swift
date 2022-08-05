//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Restaurant: Model {
  public let id: String
  public var restaurantName: String
  public var menus: List<Menu>?

  public init(id: String = UUID().uuidString,
      restaurantName: String,
      menus: List<Menu>? = []) {
      self.id = id
      self.restaurantName = restaurantName
      self.menus = menus
  }
}
