//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct CustomerWithMultipleFieldsinPK: Model {
  public let id: String
  public var dob: Temporal.DateTime
  public var date: Temporal.Date
  public var time: Temporal.Time
  public var phoneNumber: Int
  public var priority: Priority
  public var height: Double
  public var firstName: String?
  public var lastName: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      dob: Temporal.DateTime,
      date: Temporal.Date,
      time: Temporal.Time,
      phoneNumber: Int,
      priority: Priority,
      height: Double,
      firstName: String? = nil,
      lastName: String? = nil) {
    self.init(id: id,
      dob: dob,
      date: date,
      time: time,
      phoneNumber: phoneNumber,
      priority: priority,
      height: height,
      firstName: firstName,
      lastName: lastName,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      dob: Temporal.DateTime,
      date: Temporal.Date,
      time: Temporal.Time,
      phoneNumber: Int,
      priority: Priority,
      height: Double,
      firstName: String? = nil,
      lastName: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.dob = dob
      self.date = date
      self.time = time
      self.phoneNumber = phoneNumber
      self.priority = priority
      self.height = height
      self.firstName = firstName
      self.lastName = lastName
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
