//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct CustomerMultipleSecondaryIndexV2: Model {
  public let id: String
  public var name: String
  public var phoneNumber: String?
  public var age: Int
  public var accountRepresentativeID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      name: String,
      phoneNumber: String? = nil,
      age: Int,
      accountRepresentativeID: String) {
    self.init(id: id,
      name: name,
      phoneNumber: phoneNumber,
      age: age,
      accountRepresentativeID: accountRepresentativeID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      phoneNumber: String? = nil,
      age: Int,
      accountRepresentativeID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.phoneNumber = phoneNumber
      self.age = age
      self.accountRepresentativeID = accountRepresentativeID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

