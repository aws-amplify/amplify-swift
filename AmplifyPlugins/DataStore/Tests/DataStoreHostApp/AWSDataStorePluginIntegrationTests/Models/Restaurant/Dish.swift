//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Dish: Model {
  public let id: String
  public var dishName: String?
  public var menu: Menu?

  public init(id: String = UUID().uuidString,
      dishName: String? = nil,
      menu: Menu? = nil) {
      self.id = id
      self.dishName = dishName
      self.menu = menu
  }
}
