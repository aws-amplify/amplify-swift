//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Salary18: Model {
  public let id: String
  public var wage: Double?
  public var currency: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    id: String = UUID().uuidString,
    wage: Double? = nil,
    currency: String? = nil
  ) {
    self.init(
      id: id,
      wage: wage,
      currency: currency,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    wage: Double? = nil,
    currency: String? = nil,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.wage = wage
      self.currency = currency
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
