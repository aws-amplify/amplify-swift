//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct CustomerOrder: Model {
  public let id: String
  public var orderId: String
  public var email: String

  public init(id: String = UUID().uuidString,
      orderId: String,
      email: String) {
      self.id = id
      self.orderId = orderId
      self.email = email
  }
}
