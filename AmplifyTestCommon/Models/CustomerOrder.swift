//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

/*
 type CustomerOrder @model
    @key(fields: ["orderId","id"]) {
    id: ID!
    orderId: String!
    email: String!
 }
 */
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
