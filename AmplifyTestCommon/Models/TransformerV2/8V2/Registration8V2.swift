//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Registration8V2: Model {
  public let id: String
  public var meeting: Meeting8V2
  public var attendee: Attendee8V2
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      meeting: Meeting8V2,
      attendee: Attendee8V2) {
    self.init(id: id,
      meeting: meeting,
      attendee: attendee,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      meeting: Meeting8V2,
      attendee: Attendee8V2,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.meeting = meeting
      self.attendee = attendee
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
