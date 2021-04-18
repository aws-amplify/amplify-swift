//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Foundation
import Amplify

public struct CoffeeShopLocation: Model {
  public let id: String
  public var address: String
  
  public init(id: String = UUID().uuidString,
      address: String) {
      self.id = id
      self.address = address
  }
}
